#!/usr/bin/perl
#Autor. jailbirt.
#Extrae fragmentos de texto para traducir y los deja en formato csv.
#Funciona para: phtml, html y js.
#el delimitador único es '|' (pipe) y deja un .csv por cada archivo de entrada en el directorio resultados.
#la primer columna queda intacta sin escapeo, la segunda es utf8, la tercera es para traducir.
#
#ATENCION, solo en el caso de js, se emplea un segundo delimitador en la segunda columna, el mismo es el %
#esto es porque al traducir, se toma todo lo de la tercer columna, se hace el correspondiente html o utf encode
#y se reemplaza por la primer columna, en los casos de javascript cada % es un sub string a reemplazar, dentro de la primer columna.
#
use strict;
use HTML::TreeBuilder 3;
use HTML::Entities;
use Data::Dumper;
binmode(STDOUT, ':utf8');

if (@ARGV[0] eq '') {
	print "something failed \n execute i.e parser4Dani.pl scripts/script.js ";
	exit;
}
#Variables Fijas.
my $destPath='./resultados/'; #Destino de los csv *Sin Traduccion*
my $file=@ARGV[0];
my (@lines);

#Levanta archivo, solo se queda lo que nos interesa.
my @resultArray=();
&retrieveData($file);
#baja a archivo.
my $result=&saveCsvData($file);
print 'Archivo .csv listo para traducir depositado en '.$result."\n";

sub retrieveData {  #Levanta Archivo y parsea, construye un array con todo lo que 'me interesa'
    my $file=$_[0];

    open(FILE, "<$file"); 
    @lines = <FILE>;
    $file=~m/(\.\w*)/g;
    my $ext=$1; #Extension.

    #Validación y cosmética de archivo.
    #
    if ($ext ne '.js') {
       &validaPhtml($file); #Trabaja sobre tags.
    }
    else{
       &validaJs($file);    #Màs complejo, trabaja linea a linea.
    }
    close(FILE);
}

sub saveCsvData {  #Recibe archivo original que esta procesando
    my ($result)=$_[0];
    $result=~s/\./_/g;
    $result=~s/\w*\///g;
    $result.='.csv';
    $result=$destPath.$result;
    open(CSV, ">$result") || die("Cannot Open File");
    foreach my $line (@resultArray) {
	    print $line;
	    print CSV $line;
    }
    close(CSV);
    return $result;
}

sub validaPhtml { #Valida entrada si nos es útil, descompone en tags armando un arbol el cual es recorrido recursivamente en recorreTreeHtml 
      my $file=$_[0];
      my $root = HTML::TreeBuilder->new;
      $root->store_pis(1);
      $root->store_declarations(1);
      $root->ignore_unknown(1);
      $root->ignore_ignorable_whitespace(1);
      $root->parse_file($file);
      my $hashDelTree=$root->disembowel();
      $hashDelTree;
      &recorreTreeHTML($hashDelTree);
      $root = $root->delete;
}

sub validaJs { #Valida linea por linea buscando quoted text.
   my ($line);
   foreach $line (@lines) {
      ##borro los comentarios al dofon, no necesitan traduccion.
      $line=~ s/\/\/(\w+\s*)//ig;
      if ($line ne '') {
	chomp($line);
	if    ($line=~ m/(\s*\/\/|.*G_GEO_.*|google|failed|reason|gmap|GEvent|oCell|function)/ig or 
               $line=~ m/.*(\.|getElementById)\((\"|\')(\w+)(\"|\')\).*/i 
	      ){ #si es comentario, funcion, o cosas de google. o entre comillas pero forma parte de una variable, sigo.
		next;
	}
         elsif ($line=~ m/.*\s*\=\s*(\"|\')(.+\s*)+(\"|\').*;$/i ){ #Matchea Variables.
			encuentraStrings($line,'variable');
        }elsif ($line=~ m/.*alert.*/gi) { #Matchea Alerts
	                encuentraStrings($line,'alert');
        }elsif ($line=~ m/.*confirm.*/gi) { #Matchea Confirm 
	                encuentraStrings($line,'confirm');
        }elsif ($line=~ m/.*jselect.*/gi) { #Matchea  Select
	                encuentraStrings($line,'select');
#ignore.}elsif ($line=~ m/(\"|\')(.+\s*)+(\"|\')/i){
#		        encuentraStrings($line,'dudoso');
	}else{
		#No nos interesa.
        }
     }
   }
}

sub encuentraStrings { #Recibe lines matches, descompone en palabras y hace push a array para Traducir.
   my $line=$_[0];
   my $queEs=$_[1];#Debuggin. Quiero saber como fue ubicado.
   my @matchesEntreComillasDobles =($line=~ m/"(.*)"/g); #variables
   my @matchesEntreComillasSimples =($line=~ m/'(.*)'/g); #variables
   my $palabraValidada='';
   if (@matchesEntreComillasDobles){
     foreach my $palabra (@matchesEntreComillasDobles){ #Si esta entre comillas Dobles.
                  $palabraValidada.=&analizaPalabras($palabra,$line).' ';
     }
   } else {
   foreach my $palabra (@matchesEntreComillasSimples){#Si esta entre comillas Simples.
                  $palabraValidada.=&analizaPalabras($palabra,$line).' ';
      }
   }
   if ($palabraValidada !~ /KOOO/g ){ # Si todas las palabras de la linea fueron aceptadas.
       my $stringUTF=&desUnicode($palabraValidada);
       #$stringUTF=~ s/javascript:\w+()\s*\;?/%/g if ($queEs eq 'variable' );
       #borro todo lo que trae el tag adentro, no esta bueno para traducir.
       #este moco, es para que reconozca toda funcion inclusive cosas absurdas como :<a href=\"javascript:subirseViajeTaxi('" % "','" % "',0);\"
       $stringUTF=~ s/\<(\/)?\w+\s*(\w+\=(\"|\\\")?\w*(\:)?(\(|\)|\'|\"|\\\'|\\\"|\+|\w*|\s*|\&|\,)*\s*)?(\;)?(\\\")?(\s)*(\\)?(\/)?(\s)*\>/%/g;
       #Remuevo las palabras conformadas por + variable +
       $stringUTF=~ s/\+\s\w+\s\+/%/g;
       #Remuevo las palabras conformadas por + variable.valor +
       $stringUTF=~ s/\+\s\w+\.\w+\s\+/%/g;
       #Ente tanto que removi me quedaron % de màs, dejo uno solo. -> %" % "%%
       $stringUTF=~ s/(%"\s%|\"%%|%\s%|%%|%\s\")+/%/g;
       $stringUTF=~ s/(%"\s%|\"%%|%\s%|%%|%\s\")+/%/g;
       #Hay ', de màs, el sub-separador es el %.
       $stringUTF=~ s/', '/%/g;
       push @resultArray, $line.'|'.decode_entities($stringUTF)."\n";
   }
}

sub analizaPalabras { #Concatena en palabra segun lo que recibe, KOOO es secuencia de escape.
      my $palabra = $_[0];
      #Si tiene Urls entre parentesis.
      #Ids|attr tipo Jquery
      #\(\(\)\)  <- esas cosas raras, no son mensajes.
      if ($palabra =~ m/(\/\w+\/)+/g       or
	  $palabra =~ m/\#\w+/ig           or 
	  $palabra =~ m/(\[\w+=.*\]).*/ig  or      
	  $palabra =~ m/(\(\(|\)\))/ig      ) 
      { 
          return 'KOOO'; #llego hasta esta palabra porque falló el primer filtro.
      }else{
          return $palabra;
      }
}

sub recorreTreeHTML {
      my $HashDelTree=$_[0];
      #Recorro los hashes del tree.
      #_content:array
      foreach my $content (@{$HashDelTree->{'_content'}}){
         if (ref($content) eq 'HTML::Element'){
                 #Es un objeto.
		 #print Dumper $content;
                 &recorreTreeHTML($content);#Recursión.
         }else {
                 #Es un string., no esta vacío , no termina como php ?>, no es comentario, $(, if, else
		 #parentesis, etc.
                 #?> 
	     if ( $content ne '' and $content !~ m/^\s+$/ and $content !~ m/.*\?>\s*$/ and 
		  $content !~ m/\s*\/\/+/g and $content !~ m/\$\(.*/g and $content !~ m/\s*(if|else)\s+/g and 
		  $content !~ m/(\(|\[|\$|&nbsp;)(\W|\s)+/g and $content !~ m/(\)|\]|\$|&nbsp;)(\W|\s)+/g ) {
                if ($content=~ m/alert\(/i)  { #Hay javascript con Unicode, tiene otro trato.
	       	   my $stringUTF=&desUnicode($content);
                   push @resultArray, $content.'|'.decode_entities($stringUTF)."\n";
		}else{
                   push @resultArray, encode_entities($content).'|'.decode_entities($content)."\n";
	        }
	    }else{
	     	  print "Lenguaje NO aceptado ->$content<-\n";
	  }
         }
      }
}

sub desUnicode { #Devuelve el caracter que representa el unicode.
	my $desUnicode= $_[0];
        $desUnicode=~ s/\\u([0-9a-f]{4})/chr(hex($1))/ieg;
	return $desUnicode;
}
