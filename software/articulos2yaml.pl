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
my $formato;
while(<>){
    $articulos.=$_ if(/^\.Artículos/../^\.FinArtículos/);
    $formato=$_ if /.Formato/;
}

$formato=substr extract_bracketed($formato,'[]','(?ms:.*?)(?=\[)'),1,-1;
my @campos;
while(my $campo=
      extract_bracketed($formato,'[]','(?ms:.*?)(?=\[)')) {
    push @campos, substr $campo, 1, -1;
}

my @articulos;
while(my $articulo=extract_bracketed($articulos,'[]','(?ms:.*?)(?=\[)')){
    push @articulos, $articulo;
}

foreach(@articulos) {
    my %struct ;
    s/\s+/ /gms; #quita cambios de línea y junta espacios en 1.
    $_=substr($_, 1,-1);
    foreach my $campo(@campos) {
	if($campo=~/autores/){
	    $struct{$campo}=autores(
		substr extract_bracketed($_,'[]','(.*?)(?=\[)'),1,-1
		);
	} else {
	    $struct{$campo}=extract_bracketed($_,'[]','(.*?)(?=\[)');
	    $struct{$campo}=~s/^\[\s*(.*)\s*\]$/$1/;
	}
    }
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
    
    
