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

# fiecare tag si fiecare secventa text va fi pusa pe cate o linie pentru a usura prelucrarea

# citire linii fisier
while read -r line; do
    # primul sed => adauga \n dupa <
    # al doilea sed => adauga \n dupa >
    # grep "\S" => selecteaza doar liniile care au elemente nenule
    
    echo "$line" | sed 's/</\n</g'  | sed 's/>/>\n/g' | grep "\S" >> formatted_tags
done < "$file"



# verifcare html valid (TBD)


cat formatted_tags

rm formatted_tags