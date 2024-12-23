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

echo '' >> "$file"

# fiecare tag si fiecare secventa text va fi pusa pe cate o linie pentru a usura prelucrarea

# citire linii fisier
while IFS= read -r line; do
    # primul sed => adauga \n dupa <
    # al doilea sed => adauga \n dupa >
    # grep "\S" => selecteaza doar liniile care au elemente nenule
    
    echo "$line" | sed 's/</\n</g'  | sed 's/>/>\n/g' | grep "\S"  >> formatted_tags.txt
done < "$file"
# cat formatted_tags.txt

# formatting text into files & arrays
indent=()
tags_st=()
tags_en=()
nr_tags_st=()
nr_tags_en=()
idx_st=0
idx_en=0
err=0

cat formatted_tags.txt | grep -oP '(?<=<)[^/<> ]+' > tags_start_tolower.txt
cat formatted_tags.txt | grep -oP '(?<=</)[^/<> ]+' > tags_end_tolower.txt

cat tags_start_tolower.txt | tr '[:upper:]' '[:lower:]' | uniq -c > tags_start.txt
cat tags_end_tolower.txt | tr '[:upper:]' '[:lower:]' | uniq -c > tags_end.txt
rm tags_start_tolower.txt; rm tags_end_tolower.txt

shopt -s lastpipe
cat tags_start.txt | while read -r line; do
    nr=$(echo "$line" | awk '{print($1)}')
    line=$(echo "$line" | awk '{print($2)}')
    if [[ "$line" = "!doctype" || "$line" = "area" || "$line" = "base" || "$line" = "br" || "$line" = "col" || "$line" = "embed" || "$line" = "hr" || "$line" = "img" || "$line" = "input" || "$line" = "link" || "$line" = "meta" || "$line" = "source" || "$line" = "track" || "$line" = "wbr" ]]; then
        continue
    fi
    tags_st[idx_st]="$line"
    nr_tags_st[idx_st]="$nr"
    echo "look: {${tags_st[idx_st]}}"
    echo "numbers: {${nr_tags_st[idx_st]}}"
    echo "{$idx_st}!"
    (( idx_st += 1 ))
done



cat tags_end.txt | while read -r line; do
    nr=$(echo "$line" | awk '{print($1)}')
    line=$(echo "$line" | awk '{print($2)}')
    tags_en[idx_en]="$line"
    nr_tags_en[idx_en]="$nr"
    : '
    echo "LOOK: {${tags_en[idx_en]}}"
    echo "NUMBERS: {${nr_tags_en[idx_en]}}"
    echo "{$idx_en}!"
    '
    (( idx_en += 1 ))
done
shopt -u lastpipe

# error checking - :(
echo "$idx_st, $idx_en"

# DOCTYPE doesn't exist - error 1
line1=$(cat formatted_tags.txt | head -1 | tr '[:upper:]' '[:lower:]')
if [ "$line1" != "<!doctype html>" ]; then
    err=1
else
    # matching number of opened and closed tags / matching close/open doesn't exist - error 2 / 3 (matching) / 4 (frequency is different)
    if [ "$idx_st" != "$idx_en" ]; then
        err=10
    else
        i=0
        while [ "$i" -lt "$idx_st" ]; do
            j=0
            while [ "$j" -lt "$idx_en" ]; do
                if [ "${tags_st[i]}" = "${tags_en[j]}" ]; then
                    break
                fi
                (( j++ ))
            done
            if [ "$j" = "$idx_en" ]; then
                err=2 # matching close doesn't exist
                break
            else
                if [ "${nr_tags_st[i]}" != "${nr_tags_en[j]}" ]; then
                    err=4 # frequency of opens and closes doesn't match
                    break
                fi
            fi
            (( i++ ))
        done

        if [ "$err" = "0" ]; then
            j=0
            while [ "$j" -lt "$idx_en" ]; do
                i=0
                while [ "$i" -lt "$idx_st" ]; do
                    if [ "${tags_st[i]}" = "${tags_en[j]}" ]; then
                        break
                    fi
                    (( i++ ))
                done
                if [ "$i" = "$idx_st" ]; then
                    err=3 # matching open doesn't exist
                    break
                else
                    if [ "${nr_tags_st[i]}" != "${nr_tags_en[j]}" ]; then
                        err=4 # frequency of opens and closes doesn't match
                        break
                    fi
                fi
                (( j++ ))
            done
        fi
    fi

    # combo is close -> open instead of open -> close - error 5


fi



if [ "$err" = "0" ]; then
    cat formatted_tags.txt | grep -oP '(?<=<)[^<> ]+' | tr '[:upper:]' '[:lower:]'  > tags_lowertags.txt
    cat formatted_tags.txt | grep -oP '^[[:space:]]*[^<]+'  > tags_text_temp.txt
    
    : '
    idx_txt=0
    cat tags_text_temp.txt | while IFS= read -r line_txt
    idx_format=0
    cat formatted_tags.txt | while read -r line; do
        if [ "$line" = "$line_txt" ]; then
            echo "$idx_format-$line_txt" >> tags_text.txt
            IFS= read -r line_txt
            (( idx_txt++ ))
        fi
        (( idx_format++ ))
    done
    
    
    rm tags_lowertags.txt
    rm tags_text_temp.txt
    '
else
    case "$err" in
        "1")
            echo "ERROR 1 - !DOCTYPE not declared in file;"
        ;;

        "2")
            echo "ERROR 2 - Corresponding close tag not found for a tag;"
        ;;

        "3")
            echo "ERROR 3 - Corresponding tag not found for a closing tag;"
        ;;

        "4")
            echo "ERROR 4 - Number of tags and their closing tags doesn't match;"
        ;;

        "5")
            echo "ERROR 1 - Incorrect closing tag found before its tag;"
        ;;

        "10")
            echo "hahahha"
        ;;
    esac
fi

# rm tags_start.txt; rm tags_end.txt
# rm formatted_tags.txt