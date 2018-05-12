#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Getopt::Long;
#use Text::Balanced qw(extract_bracketed);
use YAML::Tiny;
use DBI;
use open qw/ :std :encoding(utf8) /;

my $yamlinput; #nombre de entrada
my $dbname; #nombre de base de datos.
usage() unless GetOptions('y=s'=>\$yamlinput, 'd=s'=>\$dbname);
usage() unless defined $yamlinput and defined $dbname;
# inicializa archivos
my $yaml=YAML::Tiny->read($yamlinput);
# conecta a la base de datos
my $dbh=DBI->connect("DBI:SQLite:dbname=$dbname","","", {
    RaiseError => 1, AutoCommit => 1 }) 
    or die "Can't open database. $DBI::errstr";
# crea las tablas
my $stc=qq(CREATE TABLE IF NOT EXISTS artículos
 (
  rowid INTEGER PRIMARY KEY AUTOINCREMENT,
  título,
  primerautor INTEGER,
  últimoautor INTEGER,
  revista INTEGER,
  año INTEGER, 
  páginas,
  volumen
  )
);
die "Falló la creación de la tabla de artículos: $DBI::errstr" 
    unless $dbh->do($stc) >= 0;
$stc=qq(CREATE TABLE IF NOT EXISTS autores
 (
  rowid INTEGER PRIMARY KEY AUTOINCREMENT,
  autor,
  autorcanónico
  )
);
die "Falló la creación de la tabla de autores: $DBI::errstr" 
    unless $dbh->do($stc) >= 0;
$stc=qq(CREATE TABLE IF NOT EXISTS listaAutores
 (
  rowid INTEGER PRIMARY KEY AUTOINCREMENT,
  autor INTEGER, 
  artículo INTEGER
  )
);
die "Falló la creación de la tabla de listaAutores: $DBI::errstr" 
    unless $dbh->do($stc) >= 0;
$stc=qq(CREATE TABLE IF NOT EXISTS revistas
 (
  rowid INTEGER PRIMARY KEY AUTOINCREMENT,
  revista,
  revistacanónica
  )
);
die "Falló la creación de la tabla de revistas: $DBI::errstr" 
    unless $dbh->do($stc) >= 0;

# prepare for dbas interactions.
my $readar=qq(SELECT rowid FROM artículos WHERE
                revista IN
                (SELECT rowid from revistas WHERE revista LIKE ?)
                AND volumen LIKE ? 
                AND páginas LIKE ?);
my $strar=$dbh->prepare($readar);
my $writear=qq(
            INSERT INTO artículos 
            (título,primerautor,últimoautor,revista,año,páginas,volumen)
            VALUES (?,?,?,?,?,?,?));
my $stwar=$dbh->prepare($writear);
my $readrev=qq(SELECT rowid FROM revistas
                     WHERE revista LIKE ?);
my $strrev=$dbh->prepare($readrev);
my $writerev=qq(INSERT INTO revistas (revista, revistacanónica)
                      VALUES (?,?));
my $stwrev=$dbh->prepare($writerev);
my $readau=qq(SELECT rowid FROM autores
                     WHERE autor LIKE ?);
my $strau=$dbh->prepare($readau);
my $writeau=qq(INSERT INTO autores (autor, autorcanónico)
                      VALUES (?,?));
my $stwau=$dbh->prepare($writeau);
my $readauid=qq(SELECT seq FROM sqlite_sequence 
                       WHERE name='listaAutores');   
my $strauid=$dbh->prepare($readauid);
my $readarid=qq(SELECT seq FROM sqlite_sequence 
                       WHERE name='artículos');   
my $starid=$dbh->prepare($readarid);
my $writearid=qq(INSERT INTO listaAutores (autor,artículo)
                             VALUES (?, ?));
my $stwarid=$dbh->prepare($writearid);


foreach(@{$yaml->[0]->{artículos}}){
    my $revistaId=getrevistaId($_->{revista});
    my @autorIds;
    foreach(@{$_->{autores}}){
	my $autorId=getautorId($_);
	push @autorIds, $autorId;
    }
    #my $autorIds=join ",",@autorIds;
    $strar->execute($_->{revista}, $_->{volumen}, $_->{páginas});
    my ($id)=$strar->fetchrow_array;
    unless($id) {
	$strauid->execute;
	my ($primerautor)=$strauid->fetchrow_array;
	$primerautor++;
	$starid->execute;
	my($artid)=$starid->fetchrow_array;
	$artid++;
	foreach(@autorIds){
	    $stwarid->execute($_,$artid);
	}
	$strauid->execute;
	my ($ultimoautor)=$strauid->fetchrow_array;
	$stwar->execute($_->{título}, $primerautor, $ultimoautor,
			$revistaId,$_->{año},
		      $_->{páginas}, $_->{volumen});
    }
}

sub getrevistaId { #regresa el ROWID de una revista
    my $revista=shift;
    $strrev->execute($revista);
    my ($id)=$strrev->fetchrow_array;
    unless(defined $id) {
	$stwrev->execute($revista, $revista);
	$strrev->execute($revista);
	($id)=$strrev->fetchrow_array;
    }
    return $id;
}

sub getautorId { #regresa el ROWID de una revista
    my $autor=shift;
    $strau->execute($autor);
    my ($id)=$strau->fetchrow_array;
    unless(defined $id) {
	$stwau->execute($autor, $autor);
	$strau->execute($autor);
	($id)=$strau->fetchrow_array;
    }
    return $id;
}



sub usage {
    print <<'FIN';
Uso
    ./yaml2db.pl -y <yaml> -d <db>
donde
    yaml es el nombre del archivo con la información en yaml
    db es el nombre de la base de datos a actualizar
FIN
    exit 1;
}
    
