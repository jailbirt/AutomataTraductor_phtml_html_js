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
	  if ($fuenteRow =~ m/\Q$columna1Limpia\E/g ){ #Si la linea del fuente coincide con la del csv. 
   #	  print "OKKKK PARA $fuenteRow CON $columna1Limpia <<---- \n";
	  #!SEGUIR ACA. Falta, encodear columna 2 y 3, luego reemplazar 2 por 3 en 1.
	  #y lo màs importante descomponer en este punto los  % %
             my $espaniol=encode_entities($rowCsv->[1]);
	     $espaniol=~ s/\s$//g; #Tiene un espacio de màs al final.
             my $traducido=encode_entities($rowCsv->[2]);
             $traducido =~ s/\r//g;
	     if ($espaniol =~ m/%/g){
                 my @subStringEs=split(/%/, $espaniol); #Tiene sub Strings#
                 my @subStringNuevo=split(/%/, $traducido); #Tiene sub Strings#
		 my $pos=0;# Los strings DEBERIAN ser iguales, respetar los %.
		 foreach my $string (@subStringEs){
	            my $stringTraducido=$subStringNuevo[$pos];
		    #Solo me importan los textos human readable
                    $lineaDelFuenteActual =~ s/\Q$string\E/$stringTraducido/g;
	            print ">SubString>Para $lineaDelFuenteActual Reemplazo /$string/$stringTraducido/g \t y Queda $lineaDelFuenteActual <--\n";
		    $pos++;
		 }
	     } else {
	         print ">Completo> Para $lineaDelFuenteActual Reemplazo /$espaniol/$traducido/g \t y Queda $lineaDelFuenteActual <--\n";
                 $lineaDelFuenteActual =~ s/\Q$espaniol\E/$traducido/g;
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
sub traduceHtml
{
 &ordenaLenght; #Ordeno por lenghts strings del csv a traducir.
 my $sourceLines=&levantaArchivoFuente;
 foreach my $row(@csvMatrix){
	 #my $command="cat $archivoFuente | sed 's#".$row->[0]."#".encode_entities($row->[2])."#g' > $archivoFuente.new";
	 #print "\n -> COMANDO[[[[[ $command ]]]]] <- \n";
	 #system($command);
	 # Open input file in read mode
           my $original=$row->[0];
           my $traducido=encode_entities($row->[2]);
	   $traducido =~ s/\r//g;
	   $sourceLines =~ s/$original/$traducido/g;
 }
 open (OUTPUTFILE, ">$archivoFuente.new");
 print OUTPUTFILE $sourceLines; 
 close OUTPUTFILE;
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
	# print Dumper @csvMatrix;
	
  @csvMatrix = sort { length $b->[1] <=> length $a->[1] } @csvMatrix;
  #print "\nDESPUES:";
  #print Dumper @csvMatrix;
}

sub reemplazaColumna   #Para el trato line a line, busca.
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
      #Agrego las tres columnas a la matrix, solo si estan traducidas.
      if ($columnas[2]) {
        #print "[0]=".$columnas[0]." [1]=".$columnas[1]." [2]=".$columnas[2]."\n"; 
        push(@{$csvMatrix[$line]}, @columnas);
      }
      $line++;
   }
}
