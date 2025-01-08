#!/bin/bash

if [ -z "$1" ]; then # daca fisierul nu a fost oferit ca argument
    # loop pana la primirea unui fisier valid ca argument
    while true; do
        echo -n "Please enter the path to an HTML file: "
        read file
        if [ -f "$file" ]; then # daca este un fisier valid
            break
        else
            echo "Not a valid file. Try again"
        fi
    done
else # daca fisierul a fost oferit ca argument
    file="$1"
    if ! [ -f "$file" ]; then 
        echo "Not a valid file"
        exit 1
    fi
fi

# adaugare newline la sfarsitul fisierului in cazul in care lipseste
if [ "$(cat "$file" | tail -1 | wc -l)" -eq 0 ]; then
    echo >> "$file"
fi

# fiecare tag si fiecare secventa text va fi pusa pe cate o linie pentru a usura prelucrarea

# citire linii fisier
while IFS= read -r line; do
    # primul sed => adauga \n dupa <
    # al doilea sed => adauga \n dupa >
    # grep "\S" => selecteaza doar liniile care au elemente nenule (nu sunt goale)
    
    echo "$line" | sed 's/</\n</g'  | sed 's/>/>\n/g' | grep "\S"  >> formatted_tags
done < "$file"


while IFS= read -r line; do
    tag_name=$(echo "$line" | grep -oP '(?<=<)[^<> ]+')
    upper_case_tag_name=$(echo "$tag_name" | tr '[:lower:]' '[:upper:]')
    if [ "$upper_case_tag_name" != "!DOCTYPE" ]; then
        tag_name=$(echo "$tag_name" | tr '[:upper:]' '[:lower:]')
         echo "$line" | sed -E "s|<[^ >]+|<$tag_name|g" >> temp
    else # daca primul cuvant al tag-ului este !DOCTYPE
        tag_name=$(echo "$upper_case_tag_name")
        second_word=$(echo "$line" | grep -oP '(?<=<)[^<>]+' | awk '{print $2}' | tr '[:upper:]' '[:lower:]')
        tag_name="$tag_name $second_word"
        echo "$line" | sed -E "s|<[^>]+|<$tag_name|g" >> temp
    fi
    
done < formatted_tags
cat temp > formatted_tags
rm temp

# Verficare HTML valid 

first_line=$(cat formatted_tags | head -1)
if [ "$first_line" != "<!DOCTYPE html>" ]; then 
    echo "ERROR - <!DOCTYPE html> not found at start of file;"
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
       if [[ "$line" = "!DOCTYPE" || "$line" = "area" || "$line" = "base" || "$line" = "br" || 
        "$line" = "col" || "$line" = "embed" || "$line" = "hr" || "$line" = "img" || 
        "$line" = "input" || "$line" = "link" || "$line" = "meta" || "$line" = "source" || 
        "$line" = "track" || "$line" = "wbr" ]]; then
            continue
        fi
        stack+=("$line")
    else  
        tag_text_only=$(echo "$line" | grep -oP '(?<=</)[^/<> ]+')
        if [ -n "$tag_text_only" ]; then  # daca tag-ul este de inchidere (si nu secveta de text)
            if [ "$tag_text_only" == "${stack[-1]}" ]; then
               unset 'stack[-1]'
            else
                echo "ERROR - Unexpected closure of tag type <$tag_text_only>;"
                rm formatted_tags
                exit 1
            fi
        fi
    fi
done < formatted_tags

if ! [ "${#stack[@]}" -eq 0 ]; then # daca stiva nu este goala => fisier invalid 
    echo "ERROR - Number of tag opens and tag closes doesn't match - left to close: <${stack[@]}>;"
    rm formatted_tags
    exit 1
fi

# daca programul ajunge aici => fisierul este valid

# indentare

indent=0
temp_indent=-1
dif_spaces=0
nr_spaces=0

# fiecare linie va fi prefixata cu numarul de ordine in ierarhie
while IFS= read -r line; do
    tag_text_only=$(echo "$line" | grep -oP '(?<=<)[^/<> ]+')
    if [ -n "$tag_text_only" ]; then # daca tag-ul este de start
        # daca tag-ul nu este unul fara tag de oprire
        if ! [[ "$tag_text_only" = "!DOCTYPE" || "$tag_text_only" = "area" || "$tag_text_only" = "base" ||
            "$tag_text_only" = "br" || "$tag_text_only" = "col" || "$tag_text_only" = "embed" ||
            "$tag_text_only" = "hr" || "$tag_text_only" = "img" || "$tag_text_only" = "input" ||
            "$tag_text_only" = "link" || "$tag_text_only" = "meta" || "$tag_text_only" = "source" ||
            "$tag_text_only" = "track" || "$tag_text_only" = "wbr" ]]; then
            line="${indent}~${line}"
            if ! [ "$tag_text_only" = "pre" ]; then
                indent=$((indent + 1))
            else
                temp_indent=$((indent))
                indent=0
            fi
        else
            line="${indent}~${line}"
        fi
    else
        tag_text_only=$(echo "$line" | grep -oP '(?<=</)[^/<> ]+')
        if [ -n "$tag_text_only" ]; then  # daca tag-ul este de inchidere (si nu secveta de text)
            if ! [ "$tag_text_only" = "pre" ]; then
                indent=$((indent - 1)) 
            else
                indent=$((temp_indent)) # se reseteaza indentul daca da de /pre
                temp_indent=-1
            fi
            line="${indent}~${line}"
        else # este secventa text
            if [ "$temp_indent" = "-1" ]; then
                nr_spaces=$(echo "$line" | grep -oP '^[ ]*' | wc -c)
                if (( nr_spaces > 0 )); then
                    nr_spaces=$((nr_spaces - 1))
                fi
                while (( nr_spaces % 4 != 0 || nr_spaces / 4 >= indent )); do
                    line=${line:1}
                    nr_spaces=$((nr_spaces - 1))
                done
                dif_spaces=$((indent * 4))
                dif_spaces=$((dif_spaces-nr_spaces))
                dif_spaces=$((dif_spaces / 4))
                line="${dif_spaces}~${line}"
            else
                line="${indent}~${line}"
            fi
        fi
    fi
    echo "$line" >> tmp_file
done < formatted_tags

cat tmp_file > formatted_tags
rm tmp_file

# transformare prefix in tab-uri (indent = n => n tab-uri <=> 4*space-uri )
while IFS= read -r line; do
    indent=$(echo "$line" | grep -oP "^[0-9]+")
    indent=$((indent * 4))
    spaces=$(printf '%*s' "$indent")
    echo "$line" | sed  -E "s/^[0-9]+~/$spaces/g" >> tmp_file
done < formatted_tags

cat tmp_file > formatted_tags
rm tmp_file


file=$(basename "$file")
cat formatted_tags > "result_$file"
echo "Pretty-Printing succesful!"
rm formatted_tags