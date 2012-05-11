#!/usr/bin/perl
#Autor. jailbirt.
#Recibe file como input source file y su correspondiente csv ( hay un wrapper .sh para procesar varios).

#A partir del cual toma fragmentos de texto traducidos y los reemplaza en los originales.
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

if (@ARGV[0] eq '' or @ARGV[1] eq '') {
	print "something failed \n execute i.e parser4Dani.pl scripts/script.js ";
	exit;
}

#Variables Fijas.
my $destPath='./resultados/'; #Destino de 
my $archivoFuente=@ARGV[0];
my $csv=@ARGV[1];
my @sourceLines=(); #Array con archivo fuente.
my @csvLines=();    #Array con archivo csv.
my @csvMatrix=();    #Matriz con archivo csv, columans por separador.
my @resultArray=(); #Array con resultados.

#Variables Custom.
my $delimitador=';';

#Main.
my $extension=&retrieveData($archivoFuente,$csv);
&separaColumnasCsv();
&manipulaReemplazos();


sub manipulaReemplazos
{
 
#Ordeno de mayor a menor, para reemplazar, un string chico puede estar solo incluido en un string màs grande ;)
 if ($extension eq 'phtml') 
 { 
  @csvMatrix = sort { length $b->[3] <=> length $a->[3] || $b cmp $a } @csvMatrix;
 }

}

sub reemplazaColumna
{
 my @columnas=$_[0];
 #1. vuelvo html entities la columna traducida (numero 3).
 print $columnas[2];
 #2. reemplazo la columna3 por la columna 1
}

sub retrieveData {  #Levanta Archivo y levanta csv
#phtml o javascript.
    open(FILE, "<$archivoFuente"); 
    @sourceLines = <FILE>;
    $archivoFuente=~m/(\.\w*)/g;
    my $ext=$1; #Extension.
    close(FILE);

#csv
    open(FILE, "<$csv"); 
    @csvLines = <FILE>;
    close(FILE);

    return $ext;
}

sub separaColumnasCsv { #arma matriz, separa filas en columnas.
my @columnas=();
my $line=0;
   foreach my $lineaCsv (@csvLines) { #Por Cada Linea del csv.
      @columnas=split(/$delimitador/, $lineaCsv);
      #Agrego las tres columnas a la matrix
      for (my $col = 0; $col <= $#columnas; $col++) {
	  print $columnas[$col]."Col $col \n";
         push(@{$csvMatrix[$line][$col]}, $columnas[$col]);
      }
      $line++;
   }
}
