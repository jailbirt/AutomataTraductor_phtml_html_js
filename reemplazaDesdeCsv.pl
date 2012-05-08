#!/usr/bin/perl
#Autor. jailbirt.
#Toma fragmentos de texto para traducidos desde un csv y los reemplaza en los originales.
#Funciona para: phtml, html y js.
#el delimitador único es '|' (pipe) y deja un .csv por cada archivo de entrada en el directorio resultados.
#la primer columna queda intacta sin escapeo, la segunda es utf8, la tercera es para traducir.
#
#ATENCION, solo en el caso de js, se emplea un segundo delimitador en la segunda columna, el mismo es el %
#esto es porque al traducir, se toma todo lo de la tercer columna, se hace el correspondiente html o utf encode
#y se reemplaza por la primer columna, en los casos de javascript cada % es un sub string a reemplazar, dentro de la primer columna.
#
# Recibe como parametro un listado con todos los archivos (y path) a reemplazar,
# para identificar el archivo vuelve atras el nombre ya que es:
# nombreArchivo_extension.csv
#
#
use strict;
use HTML::TreeBuilder 3;
use HTML::Entities;
use Data::Dumper;
binmode(STDOUT, ':utf8');

