#!/bin/bash

# loop pana la primirea unui fisier valid ca argument

while true; do
    echo -n "Please enter the path to an HTML file: "
    read file
    if [ -f "$file" ]; then
        break
    else
        echo "Not a valid file. Try again"
    fi
done

if [ "$(cat "$file" | tail -1 | wc -l)" -eq 0 ]; then
    echo >> "$file"
fi

# fiecare tag si fiecare secventa text va fi pusa pe cate o linie pentru a usura prelucrarea

# citire linii fisier
while IFS= read -r line; do
    # primul sed => adauga \n dupa <
    # al doilea sed => adauga \n dupa >
    # grep "\S" => selecteaza doar liniile care au elemente nenule
    
    echo "$line" | sed 's/</\n</g'  | sed 's/>/>\n/g' | grep "\S"  >> formatted_tags
done < "$file"
cat formatted_tags

# Verficare HTML valid 

first_line=$(cat formatted_tags | head -1)

if [ "$first_line" != "<!DOCTYPE html>" ]; then 
    echo "<!DOCTYPE html> not found"
    rm formatted_tags
    exit 1
fi

# se va folosi o stiva in care vor fi memorate tag-urile de start
# acestea vor fi eliminate in momentul in care se intalneste un tag de sfarist egal 
# daca stack-ul nu este gol la final sau daca se intalneste alt tag de sfarsit fata 
# de tag-ul de start din varful stive => fisier invalid


stack=()

while IFS= read -r line; do
    tag_text_only=$(echo "$line" | grep -oP '(?<=<)[^/<> ]+')

    if [ -n "$tag_text_only" ]; then # daca tag-ul este de start
        line="$tag_text_only"
        if [[ "$line" = "!DOCTYPE" || "$line" = "area" || "$line" = "base" || "$line" = "br" || "$line" = "col" || "$line" = "embed" || "$line" = "hr" || "$line" = "img" || "$line" = "input" || "$line" = "link" || "$line" = "meta" || "$line" = "source" || "$line" = "track" || "$line" = "wbr" ]]; then
            continue
        fi
        stack+=("$line")
    else  
        tag_text_only=$(echo "$line" | grep -oP '(?<=</)[^/<> ]+')
        if [ -n "$tag_text_only" ]; then  # daca tag-ul este de inchidere (si nu secveta de text)
            if [ "$tag_text_only" == "${stack[-1]}" ]; then
               unset 'stack[-1]'
            else
                echo "Unexpected closure of tag (</$tag_text_only>)"
                rm formatted_tags
                exit 1
            fi
        fi

    fi
done < formatted_tags

if ! [ "${#stack[@]}" -eq 0 ]; then # daca stiva nu este goala => fisier invalid 
    rm formatted_tags
    exit 1
fi

# daca programul ajunge aici => fisierul este valid

# indentare

indent=0
# fiecare linie va fi prefixata cu numarul de ordine in ierarhie
while IFS= read -r line; do

   
    tag_text_only=$(echo "$line" | grep -oP '(?<=<)[^/<> ]+')
    if [ -n "$tag_text_only" ]; then # daca tag-ul este de start
        # daca tag-ul nu este unul fara tag de oprire
        if ! [[ "$tag_text_only" = "!DOCTYPE" || "$tag_text_only" = "area" || "$tag_text_only" = "base" || "$tag_text_only" = "br" || "$tag_text_only" = "col" || "$tag_text_only" = "embed" || "$tag_text_only" = "hr" || "$tag_text_only" = "img" || "$tag_text_only" = "input" || "$tag_text_only" = "link" || "$tag_text_only" = "meta" || "$tag_text_only" = "source" || "$tag_text_only" = "track" || "$tag_text_only" = "wbr" ]]; then
            line="${indent}${line}"
            indent=$((indent + 1))
        fi
    
    else
        tag_text_only=$(echo "$line" | grep -oP '(?<=</)[^/<> ]+')
        if [ -n "$tag_text_only" ]; then  # daca tag-ul este de inchidere (si nu secveta de text)
            indent=$((indent - 1))
            line="${indent}${line}"
        else # etste secventa text
            line="${indent}${line}"
        fi
    fi

    
    # prefixare
    echo "$line" >> tmp_file

done < formatted_tags

cat tmp_file > formatted_tags
 rm tmp_file