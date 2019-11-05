#!/usr/bin/perl

# CONCEPT ANNOTATION PROPAGATION for BRAT RAPID ANNOTATION TOOL
#
# From existing annotations of concepts saved in BRAT stand-off
# annotation files (*.ann), this script searches for similar concepts
# to be annotated in the remaining part of the corpus to process and
# produces annotation files combining existing annotations (e.g., in
# case of automatic pre-annotation) with annotations found during the
# propagation process. Using this script supposes to process corpus
# files in the logic order of the files within a directory...
#
# Warning! Files from BRAT (*.txt and *.ann) must be encoded in UTF-8
#
# perl propagation.pl -r <directory containing files> -s <starting file name>


<<DOC;
Cyril Grouin - cyril.grouin@limsi.fr - Sat Oct 25 11:53:30 2015

	propagation.pl

Input: text corpus with stand-off annotations from BRAT

Output: same files with existing annotations propagated

To do:

Bugs and problems:

DOC



###
# Packages and variables

use strict;
use File::Copy;
use open ':utf8';              # Management of characters with diacritics

use vars qw($opt_r $opt_s);    # Options: -r (directory), -s (starting file)
use Getopt::Std;
&getopts("r:s:");

my @directory=<$opt_r/*ann>;   # Directory containing text and annotation files
my $startingFile=$opt_s;       # Starting file for the annotation propagation

my %firstAnnotations=();       # Annotations found in previously annotated files
my %firstRelations=();         # Relations found in previously annotated files
my %globalFrequency=();        # Frequency of annotations in the whole corpus
my ($minimumSize,$minimumFrequency,$forbiddenTag,$userCommentValue,$forbiddenToken)=(3,0,"","STOP","");


###
# Program

configuration();
annotations();
dossier();


###
# Sub-program

sub dossier() {

  ###
  # For each file from the directory, annotation propagation starts
  # when file to process corresponds to the starting file ($flag==1)

  my $flag=0;

  foreach my $annotationFile (@directory) {

    # Annotation propagation starts if starting file is found
    if ($annotationFile=~/$startingFile/) { $flag=1; }
    if ($flag==1) {
      warn "Processing $annotationFile\n";

      # Temporary file for the annotation file
      my $temporaryAnnotationFile=$annotationFile; $temporaryAnnotationFile=~s/ann$/tmp/;
      copy("$annotationFile","$temporaryAnnotationFile");


      ###
      # Existing annotations from this file (coming from automatic
      # pre-annotation or annotations done previously) are saved in a
      # hash table %existingAnnotations as well as in the variable
      # $allExistingAnnotations (will be reprinted in the final
      # annotation file)

      my $allExistingAnnotations="";
      my %existingAnnotations=();
      my %propagatedAnnotations=();
      my $i=1;

      open(E,$annotationFile);
      while (my $line=<E>) {
	chomp $line;
	# Parsing of BRAT annotation format
	my ($id,$infos,$token)=split(/\t/,$line);
	my ($tag,$start,$end)=split(/ /,$infos);
	$existingAnnotations{"$token$start$end"}++;
	$allExistingAnnotations.="$line\n";
	$i++;
      }
      close(E);


      ###
      # Identification of annotations made on previous files

      my $textFile=substr($annotationFile,0,length($annotationFile)-3)."txt";
      open(E,$textFile);

      # The wholeness of the file is saved in a variable $fileContent
      # on which the function index() will be applied in order to
      # identify starting offset of character for each new annotation
      # found in the file

      my $fileContent="";
      while (my $line=<E>) { $fileContent.=$line; }

      my %tokensLeft=();
      my %tokensRight=();

      foreach my $token (sort keys %firstAnnotations) {
	# Identification of all occurrences of this token in the file
	my $startingOffset = index $fileContent, $token;
	while ($startingOffset>=0) {
	  my $endingOffset=$startingOffset+length($token);
	  if ($globalFrequency{$token}>=$minimumFrequency && !exists $existingAnnotations{"$token$startingOffset$endingOffset"}) {
	    $propagatedAnnotations{"T$i\t$firstAnnotations{$token} $startingOffset $endingOffset\t$token"}++;
	    # Tokens are saved in hash table to produce relations
	    $tokensLeft{"$token"}="T$i";
	    $tokensRight{"$token"}="T$i";
	    warn "$token T$i\n";
	    $i++;
	  }
	  my $rest=$startingOffset+1;
	  $startingOffset = index $fileContent,$token,$rest;
	}
      }

      close(E);

      # Production of relations between two concepts (excluding a
      # concept with itself)
      foreach my $tokenL (sort keys %tokensLeft) {
	warn ":: $tokenL\n";
	foreach my $tokenR (sort keys %tokensRight) {
	  if ($tokenL ne $tokenR) {
	    warn "$tokenL $tokenR\n";
	    if (exists $firstRelations{"$tokenL,$tokenR"}) {
	      warn "Found $tokenL,$tokenR",$firstRelations{"$tokenL,$tokenR"},"\n";
	    }
	  }
	}
      }


      ###
      # Production of the final annotation file (combination of
      # existing annotations from $allExistingAnnotations with
      # propagated annotations from %propagatedAnnotations) and
      # deletion of temporary annotation file

      open(S,">$annotationFile");
      print S "$allExistingAnnotations";
      foreach my $entry (sort keys %propagatedAnnotations) { print S "$entry\n"; }
      close(S);

      unlink("$temporaryAnnotationFile");

    }
  }

}


sub annotations() {

  ###
  # Existing annotations from each *.ann file are saved in a hash
  # table %firstAnnotations (correspondence token/tag) if token's
  # length fits the defined threshold (minimum size)

  foreach my $ann (@directory) {

    # Essais relations
    my %correspondenceToken=();

    # First, user's comment associated with annotations are parsed, in
    # order to localize annotations that must not be propagated (the
    # value of the comment is defined in the configuration file,
    # namely STOP)

    my %stop=();      # Hash table containing annotation ID to do not propagate
    open(E,$ann);
    while (my $line=<E>) {
      chomp $line;
      if ($line=~/AnnotatorNotes (T\d+)\t$userCommentValue/) { $stop{$1}++; }

      # Relation annotation
      if ($line=~/^(T\d+)\t\S+ \S+ \S+\t(.*)$/) { $correspondenceToken{$1}=$2; }
      if ($line=~/^R\d+\t(.+) Arg1\:(T\d+) Arg2\:(T\d+)/) {
	my ($type,$id1,$id2)=($1,$2,$3);
	my $key=$correspondenceToken{"$id1"}.",".$correspondenceToken{"$id2"};
	$firstRelations{$key}=$type;
	warn "+++ $key : $type ($id1 $id2)\n";
      }

    }
    close(E);


    # Second, existing annotations of concepts are saved, except for
    # annotations that must not be propagated, as expressed by the
    # user's comment (previous step)

    open(E,$ann);
    while (my $line=<E>) {
      chomp $line;

      # Only lines of annotation of concepts are processed (in order
      # to avoid propagation of user's comments from the
      # AnnotatorNotes field)

      if ($line=~/^T/ && $line!~/AnnotatorNotes/) {
	my ($id,$info,$token)=split(/\t/,$line);
	my ($tag,$start,$end)=split(/ /,$info);
	if (length($token)>=$minimumSize && $tag!~/^$forbiddenTag$/ && $token!~/^$forbiddenToken$/ && !exists $stop{$id}) {
	  $firstAnnotations{$token}=$tag;
	  $globalFrequency{$token}++;
	}
      }
    }

    close(E);
  }

}


sub configuration() {

  ###
  # Script general configuration

  open(E,"propagation-configuration.txt") or die "Configuration file not found.\n";
  while (my $line=<E>) {
    chomp $line;
    if ($line=~/^size=(.+)$/) { $minimumSize=$1; }
    if ($line=~/^frequency=(.+)$/) { $minimumFrequency=$1; }
    if ($line=~/^forbidden=(.+)$/) { my $l=$1; $l=~s/\,/\|/g; $forbiddenTag="(".$l.")"; }
    if ($line=~/^value=(.+)$/) { $userCommentValue=$1; }
    if ($line=~/^blacklist=(.+)$/) { my $l=$1; $l=~s/\,/\|/g; $forbiddenToken="(".$l.")"; }
  }
  close(E);

}
