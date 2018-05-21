#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Encode qw(decode_utf8);
use Text::Balanced qw(extract_bracketed);
use YAML::Tiny;
use open qw/ :std :encoding(utf8) /;
use Getopt::Long;

my $input; #nombre de entrada
my $output; #nombre de salida
my $re; #regular expression
my $are; #regular expression for authors
my $fields; #interpretation of fields
my $cvu; #cvu number
my $curp; #curp id
@ARGV=map { decode_utf8($_,1) } @ARGV;

usage() unless GetOptions('i=s'=>\$input, 'o=s'=>\$output, 'r=s'=>\$re,
			  'a=s'=>\$are, 'f=s'=>\$fields,
			  'cvu=s'=>\$cvu, 'curp=s'=>\$curp);  
usage() unless defined $input and defined $re and
    defined $are and defined $fields;

my @fields=split ' ', $fields;
usage() unless validatefields(@fields); #check all fields valid
open(INPUT, '<', $input) or die "Couldn't open $input: $!";
if(defined $output){
    open(OUTPUT, '>', $output) or die "Couldn't open $output: $!";
}else{
    *OUTPUT=*STDOUT;
}
binmode(INPUT, ":utf8");
$re=qr/$re/i;
die "Invalid entry regular expression $re" unless defined $re;
$are=qr/$are/i;
die "Invalid author regular expression $are" unless defined $are;

my @required=qw(autores título revista volumen páginas año 
                doi infoextra ); #required fields (content may be empty)
my %required;
map {$required{$_}=1} @required;


my $yaml=YAML::Tiny->new();
my %inv;
$inv{investigador}->{cvu}=$cvu if defined $cvu;
$inv{investigador}->{curp}=$curp if defined $curp;
push @{$yaml}, \%inv if defined $inv{investigador};

my @articulos;
$/=""; #Separa en líneas en blanco.
while(<INPUT>){
    chomp;
    next unless /^\.Artículos/../^\.FinArtículos/;
    next if /^.Artículos/;
    next if /^.FinArtículos/;
    s/\n/ /g;
    s/\s+/ /g;
    push @articulos, $_ unless /^$/;
}

my %articulos;
foreach(@articulos){
    my %struct;
    m/$re/ or die "$_ doesn't match";
    {
	no strict "refs";
	foreach(0..$#fields){
	    $struct{$fields[$_]}=${$_+1};
	}
    }
    my $autores=$struct{autores};
    my @autores;
    while($autores=~ s/$are// ){
	push @autores, $1;
    }
    die "Me sobraron autores $autores en $_" if $autores;
    $struct{autores}=[@autores];
    defined $struct{$_} or delete $struct{$_} foreach keys %struct;
    push @{$articulos{artículos}}, \%struct;
}
push @{$yaml}, \%articulos if defined $articulos{artículos};
my $out=$yaml->write_string();
say OUTPUT $out;

sub validatefields {
    my %fields;
    ++$fields{$_} while($_=shift);
    foreach(@required){
	return 0 unless $fields{$_};
    }
    return 1;
}

	

sub usage {
    print <<'FIN';
Use
    ./re2yaml.pl -i <input file>                \
                 -o <output file>               \
                 -r <regular expression>        \
                 -a <author regular expression> \
                 -f <fields>                    \
                 -cvu <cvu number>              \
                 -curp <curp id>
converts input file to yaml using regular expression to parse
bibliographical entry and another regular expression to parse
individual authors. Consecutive matches correspond to the list of
space separated fields, which should contain 
    autores título revista volumen páginas año
in the desired order.

FIN
    exit 1;
}
