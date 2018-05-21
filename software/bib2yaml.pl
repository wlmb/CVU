#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Getopt::Long;
use BibTeX::Parser;
use IO::File;
use List::Util qw/pairs/;
use YAML::Tiny;
use open qw/ :std :encoding(utf8) /;

my $cvu; #número CVU
my $curp; #número curp
my $input; #nombre de entrada
my $output; #nombre de salida.
usage() unless GetOptions('i=s'=>\$input, 'o=s'=>\$output,
			  'cvu=s'=>\$cvu, 'curp=s'=>\$curp
    );  
usage() unless defined $input;
if(defined $output){
    open(OUTPUT, '>', $output) or die "No pude abrir $output: $!";
}else{
    *OUTPUT=*STDOUT;
}

my $yaml=YAML::Tiny->new();
my %inv;
$inv{investigador}->{cvu}=$cvu if defined $cvu;
$inv{investigador}->{curp}=$curp if defined $curp;
push @{$yaml}, \%inv if defined $inv{investigador};

my %articulos;
my $hinput=IO::File->new($input) or die "No pude abrir $input";
my $parser=BibTeX::Parser->new($hinput);
my @fields= qw(título title revista journal volumen volume páginas pages
           año year doi doi issn issn eissn eissn);
while(my $entry=$parser->next){
    next unless $entry->parse_ok;
    my $type=$entry->type;
    next unless $type eq "ARTICLE";
    my %struct;
    $struct{autores}=[map {detex($_->to_string)} $entry->author];
    $struct{$_->[0]}=detex($entry->field($_->[1])) foreach pairs @fields;
    $struct{páginas}//=detex($entry->field("article-number"));
    map {delete $struct{$_->[0]} unless defined $struct{$_->[0]}}
        pairs @fields;
    push @{$articulos{artículos}}, \%struct;
}
#push @{$yaml->[1]->{"artículos"}}, \%struct;
push @{$yaml}, \%articulos if defined $articulos{artículos};

my $out=$yaml->write_string();
say OUTPUT $out;

sub detex {
    local $_=shift;
    return unless defined;
    s/\\&/&/g;
    s/[\{]?\\'[\{]?a\}?\}?/á/g;
    s/[\{]?\\'[\{]?e\}?\}?/é/g;
    s/[\{]?\\'[\{]?i\}?\}?/í/g;
    s/[\{]?\\'[\{]?\\i ?\}?\}?/í/g;
    s/[\{]?\\'[\{]?o\}?\}?/ó/g;
    s/[\{]?\\'[\{]?u\}?\}?/ú/g;
    s/[\{]?\\\"[\{]?u\}?\}?/ü/g;
    s/[\{]?\\~[\{]?n\}?\}?/ñ/g;
    s/[\{]?\\'[\{]?A\}?\}?/Á/g;
    s/[\{]?\\'[\{]?E\}?\}?/É/g;
    s/[\{]?\\'[\{]?I\}?\}?/Í/g;
    s/[\{]?\\'[\{]?\\I ?\}?\}?/Í/g; #??
    s/[\{]?\\'[\{]?O\}?\}?/Ó/g;
    s/[\{]?\\'[\{]?U\}?\}?/Ú/g;
    s/[\{]?\\\"[\{]?U\}?\}?/Ü/g;
    s/[\{]?\\~[\{]?N\}?\}?/Ñ/g;
    s/{//g;
    s/}//g;
    return $_;
}

sub usage {
    print <<'FIN';
Use
   ./bib2yaml.pl -i <input file>                \
                 -o <output file>               \
                 -cvu <cvu number>              \
                 -curp <curp id> 
converts input bibtex file to yaml.

FIN
    exit 1;
}

