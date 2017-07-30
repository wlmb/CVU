#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use utf8;
use Getopt::Long;
use Text::Balanced qw(extract_bracketed);
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
  título,
  autores,
  revista,
  año, 
  páginas,
  volumen
  )
);
die "Falló la creación de la tabla de artículos: $DBI::errstr" 
    unless $dbh->do($stc) >= 0;
$stc=qq(CREATE TABLE IF NOT EXISTS autores
 (
  autor,
  autorcanónico
  )
);
die "Falló la creación de la tabla de autores: $DBI::errstr" 
    unless $dbh->do($stc) >= 0;
$stc=qq(CREATE TABLE IF NOT EXISTS revistas
 (
  revista,
  revistacanónica
  )
);
die "Falló la creación de la tabla de revistas: $DBI::errstr" 
    unless $dbh->do($stc) >= 0;

foreach(@{$yaml->[0]->{artículos}}){
    my $revistaId=getrevistaId($_->{revista});
    my @autorIds;
    foreach(@{$_->{autores}}){
	my $autorId=getautorId($_);
	push @autorIds, $autorId;
    }
    my $autorIds=join ",",@autorIds;
    my $read=qq(SELECT ROWID FROM artículos WHERE
                revista IN
                (SELECT ROWID from revistas WHERE revista LIKE ?)
                AND volumen LIKE ? 
                AND páginas LIKE ?);
    my $str=$dbh->prepare($read);
    $str->execute($_->{revista}, $_->{volumen}, $_->{páginas});
    my ($id)=$str->fetchrow_array;
    unless($id) {
	my $write=qq(
            INSERT INTO artículos (título,autores,revista,año,páginas,volumen)
            VALUES (?,?,?,?,?,?));
	my $stw=$dbh->prepare($write);
	$stw->execute($_->{título}, $autorIds, $revistaId,$_->{año},
		      $_->{páginas}, $_->{volumen});
    }
}

sub getrevistaId { #regresa el ROWID de una revista
    my $revista=shift;
    my $read=qq(SELECT ROWID FROM revistas
                     WHERE revista LIKE ?);
    my $str=$dbh->prepare($read);
    $str->execute($revista);
    my ($id)=$str->fetchrow_array;
    unless(defined $id) {
	my $write=qq(INSERT INTO revistas (revista, revistacanónica)
                      VALUES (?,?));
	my $stw=$dbh->prepare($write);
	$stw->execute($revista, $revista);
	$str->execute($revista);
	($id)=$str->fetchrow_array;
    }
    return $id;
}

sub getautorId { #regresa el ROWID de una revista
    my $autor=shift;
    my $read=qq(SELECT ROWID FROM autores
                     WHERE autor LIKE ?);
    my $str=$dbh->prepare($read);
    $str->execute($autor);
    my ($id)=$str->fetchrow_array;
    unless(defined $id) {
	my $write=qq(INSERT INTO autores (autor, autorcanónico)
                      VALUES (?,?));
	my $stw=$dbh->prepare($write);
	$stw->execute($autor, $autor);
	$str->execute($autor);
	($id)=$str->fetchrow_array;
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
    

__END__

my $articulos;
while(<>){
    $articulos.=$_ if(/^\.Artículos/../^\.FinArtículos/);
}
my @articulos;
while(my $articulo=extract_bracketed($articulos,'[]','(?ms:.*?)(?=\[)')){
    push @articulos, $articulo;
}
#my $last=$articulos[-1];
#say $last;
foreach(@articulos){
    my %struct;
    s/\s+/ /gms; #quita cambios de línea
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
    
    
