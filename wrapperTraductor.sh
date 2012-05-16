#!/bin/bash
#Recibe path de files, compone con sus respectivos csv y ejecuta traduccion
pathSources='../views'
pathCsv='../csv'
for i in $(find $pathSources -iname '*.phtml') ; do 
    echo -e "Traduciendo $i con $pathCsv/$(echo $i|sed s:/.*/::g|sed -e "s:\.\.::g"|cut -d. -f1)_phtml.csv \n"
    ./reemplazaDesdeCsv.pl $i $pathCsv/$(echo $i|sed s:/.*/::g|sed -e "s:\.\.::g"|cut -d. -f1)_phtml.csv
done
#for i in $(find $pathSources -iname *.js) ; do 
#    echo -e "Traduciendo $i \n"
#    ./reemplazaDesdeCsv.pl $i $pathCsv/$(echo $i|sed s:/.*/::g|sed -e "s:\.\.::g"|cut -d. -f1)_js.csv
#done
