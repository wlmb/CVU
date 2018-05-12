#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Getopt::Long;
use YAML::Tiny;
use open qw/ :std :encoding(utf8) /;

my $pubin; #nombre de entrada con lista de publicaciones
my $canonin; #nombre de entrada con lista de revistas con issn
my $comunin; #nombre de entrada con nombres comunes y canónicos
my $pubout; #nombre de salida de publicaciones
my $comunout; #nombre de salida de nombres comunes

usage() unless GetOptions('pi=s'=>\$pubin, 'ci=s'=>\$canonin, 
    'po=s'=>\$pubout, 'cmi=s'=>\$comunin, 'cmo=s'=>\$comunout);
usage() unless defined $pubin and defined $canonin and defined $pubout;

# inicializa archivos
my $pubs=YAML::Tiny->read($pubin);
my $canon=YAML::Tiny->read($canonin);
my $comundic=defined $comunin?YAML::Tiny->read($comunin):YAML::Tiny->new({}); 
my $index=0;
my %table;
foreach(@{$canon}){ #prepare lookup table
    my $normal=normalize($_->{nombre});
    my @words=split ' ', $normal;
    map {$table{$_}{$index}=1;} map {abbrevs($_)} @words;
} continue { ++$index; }
my %failed;
foreach(@{$pubs}){
    next unless $_->{artículos};
    foreach(@{$_->{artículos}}){
	next if $failed{$_->{revista}};
	my ($canon, $issnid)=busca($_->{revista});
	if($canon){
	    $_->{revistaCanónica}=$canon;
	    $_->{issn}=$issnid;
	}else{
	    ++$failed{$_->{revista}};
	}
    }
}
$pubs->write($pubout);
$comundic->write($comunout) if defined $comunout;

sub busca {
    my $orig=shift;
    my $comun=shift//$orig;
    my $dic=$comundic->[0]; # diccionario
    return ($dic->{$comun}->{canon}, $dic->{$comun}->{issn}) 
	if defined $dic->{$comun};
    while(1){
	my %results; #array of search results.
	my $normal=normalize($comun); #normalize
	my @words=split ' ', $normal; #split into individual words
	foreach (@words){
	    $results{$_}++ foreach(keys %{$table{$_}});
	}
	my @a=grep {$results{$_} == @words} keys %results;
	say "Nombre original: $orig\nBuscar: $comun";
	my $i=0;
	print "-1. MANUAL\n";
	print "0. TERMINAR\n";
	print ++$i, 
	   ". $canon->[$_]->{issn}: $canon->[$_]->{nombre}\n" foreach(@a);
	my $respuesta=prompt(
	    "Escribe el número correspondiente u otros términos de búsqueda: "
	    );
	if($respuesta=~/^\s*-?\d+\s*$/){
	    say("Número invalido"), next 
		unless $respuesta >= -1 && $respuesta <=  @a;
	    return ("", "") if $respuesta == 0; #tira la toalla
	    if($respuesta==-1){ #caso manual
		my ($mcanon, $missn)=manual($orig);
		next unless $mcanon;
		$dic->{$orig}->{canon} = $mcanon;
		$dic->{$orig}->{issn} = $missn;
	    }
	    if($respuesta >=1 && $respuesta <=  @a){
		$dic->{$orig}->{canon} =
		    $canon->[$a[$respuesta-1]]->{nombre};
		$dic->{$orig}->{issn} =
		    $canon->[$a[$respuesta-1]]->{issn};
	    }
	    return ($dic->{$orig}->{canon}, $dic->{$orig}->{issn});
	}
	$comun=$respuesta;
    }
}

sub normalize { #normalize string
    my $s=shift; 
    my $normal=lc $s; #normalize to lowercase
    $normal=~s/[^[:alnum:]\s]/ /g; #remove punctuation
    $normal=~tr/áéíóúäëïöüàèìòùñ/aeiouaeiouaeioun/; #use only ascii chars.
    $normal=~s/\s+/ /g; #replace multiple to single spaces
    $normal=~s/^ //; #eliminate leading space
    $normal=~s/ $//; #and trailing space
    return $normal;
}

sub manual {
    my $orig=shift;
    say $orig;
    my $canon=uc prompt("Nombre canónico: ");
    return 0 unless $canon;
    my $issn=uc prompt("ISSN: ");
    return 0 unless $issn;
    my $ya=lc prompt("$issn $canon. ¿Correcto? (s/n) ");
    return 0 unless $ya=~m/^\s*[ys1]/;
    return ($canon, $issn);
}
	
sub abbrevs {
    my $word=shift;
    my @letters=split '', $word;
    my @abbrevs;
    my @abbrev;
    while($_=shift @letters){
	push @abbrev, $_;
	push @abbrevs, join '',@abbrev;
    }
    return @abbrevs;
}

sub prompt {
    print @_;
    chomp(my $r=<>);
    return $r;
}

sub usage {
    print <<'FIN';
Uso
    ./yaml2canon.pl -pi <pubs in>  -ci <canon in> \
                    -po <pubs out> [-cmi <common in>] [-cmo <common out>]
donde
    <pubs in> es el nombre del archivo con la lista de publicaciones en yaml
    <cannon in> el de la lista de nombres canónicos de revistas e issns
    <pubs out>  la salida de publicaciones canonizadas
    <common in> diccionario de nombres comunes de entrada
    <common out> diccionario de nombres comunes de salida
FIN
    exit 1;
}
