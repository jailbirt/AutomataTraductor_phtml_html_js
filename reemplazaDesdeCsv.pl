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
#TODO: extenderlo a .php
#      tiene que tomar los alerts de html y phtml
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
chomp ($archivoFuente);
my $csv=@ARGV[1];
chomp ($csv);
my @sourceLines=(); #Array con archivo fuente.
my @csvLines=();    #Array con archivo csv.
my @csvMatrix=();    #Matriz con archivo csv, columans por separador.
my @resultArray=(); #Array con resultados.

#Variables Custom.
my $delimitador='\|';

#Main.
my $extension=&retrieveData($archivoFuente,$csv);#Alimenta Arrays con csv y archivo fuente.
&separaColumnasCsv();                            #Separa en columnas 

if ($extension =~ m/.?html/g) {
   &traduceHtml();
}elsif ($extension =~ m/js/g){
   &traduceJavascript();
}

sub traduceJavascript
{
 my $indice = 0;
 my $nuevoFuente='';
 foreach my $fuenteRow ( @sourceLines) {
     my $columna1Limpia='';
     my $lineaDelFuenteActual=$sourceLines[$indice];#Para trabajar en un string
     foreach my $rowCsv(@csvMatrix){
	  $columna1Limpia=$rowCsv->[0];	
	  $columna1Limpia =~ s/(^\"|\"$)//g;
	  next if ( $columna1Limpia =~ m/(if|else)\s*\(/g and $columna1Limpia !~ m/Alert/ig );
	  if ($columna1Limpia !~ m/^\s*$/g and $fuenteRow =~ m/\Q$columna1Limpia\E/g ){ #Si la linea del fuente coincide con la del csv. 
  	  print "OKKKK PARA  [[[[ $fuenteRow ]]] CON [[[ $columna1Limpia ]]] <<---- \n";
	  #encodea columna 2 y 3, luego reemplazar 2 por 3 en la oracion.
	  #y lo màs importante descomponer en este punto los  % %
             my $espaniol=$rowCsv->[1];
	     $espaniol=~ s/\s$//g; #Tiene un espacio de màs al final.
             my $traducido=$rowCsv->[2];
             $traducido =~ s/\r//g;
	     if ($espaniol =~ m/%/g){
                 my @subStringEs=split(/%/, $espaniol); #Tiene sub Strings#
                 my @subStringNuevo=split(/%/, $traducido); #Tiene sub Strings#
		 my $pos=0;# Los strings DEBERIAN ser iguales, respetar los %.
		 foreach my $string (@subStringEs){
	            my $stringTraducido=encode_entities($subStringNuevo[$pos]);
		    $stringTraducido = "$1$stringTraducido$2" if ($lineaDelFuenteActual =~ m/(&\w+;)\w+(&\w+;)/g); #Molestos Botones..
		    $string=encode_entities($string);
		    #Pequeño moco con algunos ',' es màs fácil resolverlo aca.
                    $string =~ s/&#39;,&#39;/'.'/; 
                    $stringTraducido =~ s/&#39;,&#39;/'.'/; 
		    #Solo me importan los textos human readable
                    $lineaDelFuenteActual =~ s/\Q$string\E/$stringTraducido/g;
	            print ">SubString>Para $lineaDelFuenteActual Reemplazo /$string/$stringTraducido/g \t y Queda $lineaDelFuenteActual <--\n";
		    $pos++;
		 }
	     } else {
                 $espaniol=encode_entities($espaniol);
                 $traducido=encode_entities($traducido);
		 $traducido = "$1$traducido$2" if ($espaniol =~ m/(&\w+;)\w+(&\w+;)/g); #Molestos Botones.
                 $espaniol =~ s/&#39;,&#39;/','/; 
                 $traducido =~ s/&#39;,&#39;/','/; 
                 $lineaDelFuenteActual =~ s/\Q$espaniol\E/$traducido/g;
	         print ">Completo> Para $lineaDelFuenteActual Reemplazo /$espaniol/$traducido/g \t y Queda $lineaDelFuenteActual <--\n";
		 
             }
         }
     }
     $nuevoFuente.=$lineaDelFuenteActual;#Agrego linea modificada o no.
     $indice++;
 }
 open (OUTPUTFILE, ">$archivoFuente.new");
 print OUTPUTFILE $nuevoFuente; 
 close OUTPUTFILE;
}
#Traduce cadenas completas SIEMPRE que sea un string mayor a una palabra.
#La segunda pasada evalua line by line.
sub traduceHtml
{
  @csvMatrix=&ordenaLenght; #Ordeno por lenghts strings del csv a traducir.
  my $sourceLines=&levantaArchivoFuente;
  foreach my $row(@csvMatrix){
     my $cantidadDePalabras = $row->[0] =~ s/((^|\s)\S)/$1/g;
     next if ( $cantidadDePalabras == 1 ); #Solo sigo si el string es mayor a una palabra
     # Open input file in read mode
     my $original=&remueveCosasDelExcel($row->[0]);
     my $traducido=&remueveCosasDelExcel($row->[2]);
     $traducido=encode_entities($traducido);
     if ($original =~ m/.*\w+.*/g and $traducido =~ m/.*\w+.*/g) {#Si tiene algo de humano
       $sourceLines =~ s/$original/$traducido/g if ($sourceLines =~ m/$original/ );
       my $originalSinQuotes ='';
       $originalSinQuotes = $original;
       $originalSinQuotes    =~ s/\&quot\;/"/g;
       $sourceLines =~ s/$originalSinQuotes/$traducido/g if ($sourceLines =~ m/$originalSinQuotes/ );
       print ">>>>>     $original ||| $originalSinQuotes \n <<<------->>> \n $traducido<<< \n";
     } 
  }
  open (OUTPUTFILE, ">$archivoFuente");
  print OUTPUTFILE $sourceLines; 
  close OUTPUTFILE;

  #Vuelvo a levantar el archivo, que se modifico arriba.
  #Ahora voy por las palabras sueltas. Hay echo de php que rompen lo anterior, de ahi esta chanchada.
  &retrieveData($archivoFuente,$csv);
  my $indice = 0;
  my $nuevoFuente='';
  foreach my $fuenteRow ( @sourceLines) {
     my $columna1Limpia='';
     my $lineaDelFuenteActual=$sourceLines[$indice];#Para trabajar en un string
     foreach my $rowCsv(@csvMatrix){
        my $cantidadDePalabras = $rowCsv->[0] =~ s/((^|\s)\S)/$1/g;
        next if ( $cantidadDePalabras != 1 ); #Solo sigo si el string es mayor a una palabra
        if ( $lineaDelFuenteActual =~ m/\>\s*\w+\s*\</ig ){ #Solo si es un tag html
           # Open input file in read mode
           my $original=&remueveCosasDelExcel($rowCsv->[0]);
           my $traducido=&remueveCosasDelExcel($rowCsv->[2]);
           $traducido=encode_entities($traducido);
           $lineaDelFuenteActual =~ s/$original/$traducido/g if ($lineaDelFuenteActual =~ m/$original/ );
           my $originalSinQuotes = $original;
           $originalSinQuotes    =~ s/\&quot\;/"/g;#Algunos html no siguen el standard y tienen " comillas.
           $lineaDelFuenteActual =~ s/$originalSinQuotes/$traducido/g if ($lineaDelFuenteActual =~ m/$originalSinQuotes/);
        }
      }
     $nuevoFuente.=$lineaDelFuenteActual;#Agrego linea modificada o no.
     $indice++;
  }
  open (OUTPUTFILE, ">$archivoFuente");
  print OUTPUTFILE $nuevoFuente; 
  close OUTPUTFILE;
   
}

#El excel agrega basura.
sub remueveCosasDelExcel {
     # Open input file in read mode
     my $stringSinBasura=$_[0];
     $stringSinBasura  =~ s/(^\"|\"$)//g; #Cosas de excel agrego "
     $stringSinBasura  =~ s/\"\"/"/g;#Cosas de excel agrego ""
     $stringSinBasura  =~ s/(^\s+|\s+$)//g;#Espacios antes y despues del texto.
     $stringSinBasura =~ s/\r//g;
     return $stringSinBasura;
}

sub levantaArchivoFuente {
    open(INPUTFILE, "<$archivoFuente"); 
    # Open output file in write mode
    my $sourceLines='';
    while (<INPUTFILE>) {
      $sourceLines.=$_;
      #Esto junta TODO en una linea, puede deshabilitarse. chomp($sourceLines);
    }
    close INPUTFILE;
    return $sourceLines;
}

#Ordeno de mayor a menor, para reemplazar, un string chico puede estar solo incluido en un string màs grande ;)
sub ordenaLenght
{
  #print "\nANTES: ";
  #print Dumper @csvMatrix;
	
  my @csvTemp = @csvMatrix;
  @csvTemp = sort { length $b->[1] <=> length $a->[1] } @csvTemp;

  #print "\nDESPUES:";
  #print Dumper @csvMatrix;
  return @csvTemp;
}

sub retrieveData {  #Levanta Archivo y levanta csv
    #phtml o javascript.
    open(FILE, "<$archivoFuente"); 
    @sourceLines = <FILE>;
    $archivoFuente=~m/(\.\w*)$/g;
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
      chomp($lineaCsv);
      @columnas=split(/$delimitador/, $lineaCsv);
      #Agrego las tres columnas a la matrix, solo si estan traducidas. #si no tiene Nada humanReadable, no agrego.
      if ( $columnas[2] and $columnas[2] !~ m/^\s*$/g and $columnas[0] =~ m/\w+/ and $columnas[1] =~ m/\w+/ ) {
        push(@{$csvMatrix[$line]}, @columnas);
      }      $line++;
   }
}
