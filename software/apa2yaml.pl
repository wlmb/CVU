#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Text::Balanced qw(extract_bracketed);
use YAML::Tiny;
use open qw/ :std :encoding(utf8) /;

my $yaml=YAML::Tiny->new();
my @articulos;
$/=""; #Separa en líneas en blanco.
while(<>){
    next unless /^\.Artículos/../^\.FinArtículos/;
    next if /^.Artículos/;
    next if /^.FinArtículos/;
    push @articulos, $_ unless /^$/;
}

foreach(@articulos){
    my %struct;
    my @autores;
    s/\s+/ /gms; #quita cambios de línea y junta espacios en uno.
    s/^\s*//; #quita espacio al principio
    s/\s*$//; #quita espacio al final.
    while(1){
	last if /^$/ or /^\(/; # termina en el año
	my $autor;
	$autor="$1 $3" if s/^\s*((\w\.\s*)+)(.*?)[\.,]\s*//;
	$autor="$2 $1" if !$autor and s/^(.*?)\s*,\s*((\w\.\s*)+)//;
	last unless $autor;
	$autor=~s/\s+/ /g;
	push @autores, "$autor";
	s/^(\s*[,&]\s*)*//; #skip commas or ampersands
    }
    my ($anho, $titulo, $revista, $volumen, $numero, $paginas);
    $anho=$1 if s/^\s*\((\d+)\)\.\s*//;
    $titulo=$1 if s/^\s*(.*?)\.\s*//;
    $revista=$1 if s/^\s*(.*?)(?=\d)//;
    $volumen=$1 if s/^\s*(\w+)//;
    $numero=$1 if s/^\s*\((\w+)\)\s*//;
    $paginas=$1 if s/^\s*,\s*(.*?)\.//;
    $struct{título}=$titulo;
    $struct{autores}=[@autores];
    $struct{revista}=$revista;
    $struct{volumen}=$volumen;
    #$struct{número}=$numero;
    $struct{páginas}=$paginas;
    $struct{año}=$anho;
    push @{$yaml->[0]->{"artículos"}}, \%struct;
}

my $out=$yaml->write_string();
say $out;
