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
cat formatted_tags.txt

# verifcare html valid (TBD)
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

cat tags_start.txt | while read -r line; do
    nr=$(echo "$line" | awk '{print($1)}')
    line=$(echo "$line" | awk '{print($2)}')
    if [[ "$line" = "area" || "$line" = "base" || "$line" = "br" || "$line" = "col" || "$line" = "embed" || "$line" = "hr" || "$line" = "img" || "$line" = "input" || "$line" = "link" || "$line" = "meta" || "$line" = "source" || "$line" = "track" || "$line" = "wbr" ]]; then
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
    echo "look: {${tags_en[idx_st]}}"
    echo "numbers: {${nr_tags_en[idx_st]}}"
    echo "{$idx_en}!"
    (( idx_en += 1 ))
done

# rm tags_start.txt; rm tags_end.txt
rm formatted_tags.txt