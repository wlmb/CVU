#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Getopt::Long;
use Text::Balanced qw(extract_bracketed);
use YAML::Tiny;
use DBI;
use Encode qw(decode);
use open qw/ :std :encoding(utf8) /;

my $dbname; #nombre de base de datos.
usage() unless GetOptions('d=s'=>\$dbname);
usage() unless defined $dbname;
# conecta a la base de datos
my $dbh=DBI->connect("DBI:SQLite:dbname=$dbname","","", {
    RaiseError => 1, AutoCommit => 1 }) 
    or die "Can't open database. $DBI::errstr";
$dbh->{sqlite_unicode}=1;
# prepare for db interactions.
# lee artículo
my $readar=qq(SELECT rowid, título, primerautor, últimoautor, revista, 
              año, páginas, volumen 
              FROM artículos);
#lee id de un autor
my $readau=qq(SELECT autor FROM listaAutores WHERE rowid=?);
#lee nombre del autor
my $readaucan=qq(SELECT autorcanónico FROM autores WHERE rowid=?);
#lee nombre de la revista e issn
my $readrev=qq(SELECT revistacanónica, issn FROM revistas WHERE rowid=?);

my $strar=$dbh->prepare($readar);
my $strau=$dbh->prepare($readau);
my $straucan=$dbh->prepare($readaucan);
my $strrev=$dbh->prepare($readrev);
$strar->execute();
while(my $row=$strar->fetchrow_hashref){
    my $registro=$row->{rowid}.  ". ";
    foreach($row->{primerautor}..$row->{últimoautor}){
	$strau->execute($_);
	my ($autorid)=$strau->fetchrow_array;
	$straucan->execute($autorid);
	my ($autor)=$straucan->fetchrow_array;
	$registro .= "$autor, ";
    }
    $strrev->execute($row->{revista});
    my ($revista, $issn)=$strrev->fetchrow_array;
    $registro.= $row->{título}. ", $revista ". $row->{volumen}. " (".
    $row->{año}. ") ". $row->{páginas} . ".";
    $registro .= " ISSN: $issn." if defined $issn;
    print "$registro\n\n";
}


sub usage {
    print <<'FIN';
Uso
    ./db2articulos.pl -d <db>
donde
    db es el nombre de la base de datos
FIN
    exit 1;
}
