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
    s/^\d*\.\s*//; # Quita número ordinal de haberlo
    my $multiples=m/&/;
    my $sawand;
    while(1){
	my $autor;
	$autor="$1 $3" if s/^\s*((\w\.\s*)+)(.*?)[\.,]\s*//;
	$autor="$2 $1" if !$autor and s/^(.*?)\s*,\s*((\w\.\s*)+)//;
	last unless $autor;
	push @autores, "$autor";
	last unless $multiples;
	last if $sawand;
	$sawand=/^(\s*,\s*)*&/;
	s/^(\s*[,&]\s*)*//; #skip commas or ampersands
    }
    my ($titulo, $revista, $volumen, $paginas, $anho)=($1,$2,$3,$4,$5) 
	if /\s*(.*?)\.\s*(.*)\s+(\d+),\s*(.*?)\s*\((\d+)\)\./;
    $struct{título}=$titulo;
    $struct{autores}=[@autores];
    $struct{revista}=$revista;
    $struct{volumen}=$volumen;
    $struct{páginas}=$paginas;
    $struct{año}=$anho;
    push @{$yaml->[0]->{"artículos"}}, \%struct;
}

my $out=$yaml->write_string();
say $out;
