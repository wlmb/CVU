#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Text::Balanced qw(extract_bracketed);
use YAML::Tiny;
use open qw/ :std :encoding(utf8) /;

my $yaml=YAML::Tiny->new();
my $articulos;
while(<>){
    $articulos.=$_ if(/^\.Artículos/../^\.FinArtículos/);
}
my @articulos;
while(my $articulo=extract_bracketed($articulos,'[]','(?ms:.*?)(?=\[)')){
    push @articulos, $articulo;
}

foreach(@articulos){
    my %struct;
    s/\s+/ /gms; #quita cambios de línea y junta espacios en 1.
    $_=substr($_, 1,-1);
    my $titulo=extract_bracketed($_,'[]','(.*?)(?=\[)');
    $titulo=~s/^\[\s*(.*)\s*\]$/$1/;
    $struct{título}=$titulo;
    $struct{autores}=autores(
	substr extract_bracketed($_,'[]','(.*?)(?=\[)'),1,-1
	);
    my $revista=extract_bracketed($_,'[]','(.*?)(?=\[)');
    $revista=~s/^\[\s*(.*)\s*\]$/$1/;
    $struct{revista}=$revista;
    my $volumen=extract_bracketed($_,'[]','(.*?)(?=\[)');
    $volumen=~s/^\[\s*(.*)\s*\]$/$1/;
    $struct{volumen}=$volumen;
    my $paginas=extract_bracketed($_,'[]','(.*?)(?=\[)');
    $paginas=~s/^\[\s*(.*)\s*\]$/$1/;
    $struct{páginas}=$paginas;
    my $anho=extract_bracketed($_,'[]','(.*?)(?=\[)');
    $anho=~s/^\[\s*(.*)\s*\]$/$1/;
    $struct{año}=$anho;
    push @{$yaml->[0]->{"artículos"}}, \%struct;
}

my $out=$yaml->write_string();
say $out;


sub autores {
    my $autores=shift;
    my @autores;
    while(my $autor=extract_bracketed($autores,'[]','(.*?)(?=\[)')){
	$autor=~s/^\[\s*(.*)\s*\]$/$1/;
	push @autores, $autor;
    }
    return [@autores];
}
    
    
