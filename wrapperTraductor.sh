#!/bin/bash
#Recibe path de files, compone con sus respectivos csv y ejecuta traduccion
pathSources='../'
pathCsv='../'
for i in $(find $pathSources -iname *.phtml) ; do 
    ./reemplazaDesdeCsv.pl $i $pathCsv/$(echo $i|sed s:/.*/::g|sed -e "s:\.\.::g"|cut -d. -f1)_phtml.csv
done
for i in $(find $pathSources -iname *.js) ; do 
    ./reemplazaDesdeCsv.pl $i $pathCsv/$(echo $i|sed s:/.*/::g|sed -e "s:\.\.::g"|cut -d. -f1)_js.csv
done
