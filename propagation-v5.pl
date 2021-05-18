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
# perl propagation.pl -r <directory containing files> -s <starting file name> -t -a

# Cette version (v5), en plus de propager les annotations existantes,
# permet également d'annoter les âges et dates qui ne l'auraient pas
# été. Cette annotation se fait au moyen de règles (plusieurs formats
# numériques et alphabétiques). Utile uniquement pour les expériences
# de délexicalisation.
# 
# perl propagation-v5.pl -a -t -r data/medina/zero/essai/

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
use utf8;

use vars qw($opt_r $opt_s $opt_t $opt_a); # Options: -r (directory), -s (starting file), -t (tokenization kept), -a (attributes propagation allowed)
use Getopt::Std;
&getopts("r:s:ta");

my @directory=<$opt_r/*ann>;   # Directory containing text and annotation files
my $startingFile=$opt_s;       # Starting file for the annotation propagation

my %firstAnnotations=();       # Annotations found in previously annotated files
my %globalFrequency=();        # Frequency of annotations in the whole corpus
my ($minimumSize,$minimumFrequency,$forbiddenTag,$userCommentValue,$forbiddenToken)=(3,0,"","STOP","");
my ($nbExistingAnnotations,$nbAfterPropagation)=(0,0);
my %attributes=();
my %types=();


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
      print STDERR "Processing $annotationFile\t";

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
      my $existNb=0;
      my $addNb=0;

      open(E,'<:utf8',$annotationFile);
      while (my $line=<E>) {
	chomp $line;
	# Parsing of BRAT annotation format
	my ($id,$infos,$token)=split(/\t/,$line);
	my ($tag,$start,$end)=split(/ /,$infos);
	$existingAnnotations{"$token$start$end"}++;
	$allExistingAnnotations.="$line\n";
	# Management of annotation numbering
	my $num=substr($id,1);
	$i=$num+1 if ($num>=$i);
	$existNb++;
	$nbExistingAnnotations++;
      }
      close(E);
      print STDERR "$existNb existing annotations\t";


      ###
      # Identification of annotations made on previous files

      my $textFile=substr($annotationFile,0,length($annotationFile)-3)."txt";
      open(E,'<:utf8',$textFile);

      # The wholeness of the file is saved in a variable $fileContent
      # on which the function index() will be applied in order to
      # identify starting offset of character for each new annotation
      # found in the file

      my $fileContent="";
      while (my $line=<E>) { $fileContent.=$line; }

      foreach my $token (sort keys %firstAnnotations) {
	# Identification of all occurrences of this token in the file
	my $startingOffset = index $fileContent, $token;
	while ($startingOffset>=0) {
	  my $endingOffset=$startingOffset+length($token);
	  if ($globalFrequency{$token}>=$minimumFrequency && !exists $existingAnnotations{"$token$startingOffset$endingOffset"}) {

	    # If option -t, tokenization must be taken into account
	    # (avoid to propagate the singular form of a token within
	    # a plural form). Problem if left context also indicated
	    # as not being an alphabetic character, the test does not
	    # seem to work anymore, and propagation is made with
	    # singular forms within plural forms...
	    if ($opt_t) {
	      my $context=substr($fileContent,$startingOffset-1,length($token)+2);
	      if ($context!~/$token(\p{L}|\d)$/ && $context!~/^(\p{L}|\#|\'|\d)$token/) {
		#warn "--- \"$token\" --- \"$context\" OK\n";
		$propagatedAnnotations{"T$i\t$firstAnnotations{$token} $startingOffset $endingOffset\t$token"}++;
		$i++;
		$addNb++;
		# Attributes propagation: A3    role T5 patient
		if ($opt_a) {
		  if (exists $attributes{$token}) {
		    my $j=$i-1;
	      	    $propagatedAnnotations{"A$i\t$types{$attributes{$token}} T$j $attributes{$token}"}++;
	       	    $i++;
		  }
		}
	      }
	    }
	    # If no option -t, propagation whatever the tokenization
	    else {
	      $propagatedAnnotations{"T$i\t$firstAnnotations{$token} $startingOffset $endingOffset\t$token"}++;
	      $i++;
	      $addNb++;
	      # Attributes propagation: A3    role T5 patient
	      if ($opt_a) {
		if (exists $attributes{$token}) {
		  my $j=$i-1;
	      	  $propagatedAnnotations{"A$i\t$types{$attributes{$token}} T$j $attributes{$token}"}++;
	       	  $i++;
		}
	      }
	    }

	  }
	  my $rest=$startingOffset+1;
	  $startingOffset = index $fileContent,$token,$rest;
	}
      }

      close(E);


      ###
      # Annotation automatique des dates et âges

      my @month=("janvier","février","mars","avril","mai","juin","juillet","août","septembre","octobre","novembre","décembre","Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre","janv","fév","avr","juil","sept","oct","nov","déc","Janv","Fév","Avr","Juil","Sept","Oct","Nov","Déc");
      for (my $year=1930;$year<=2022;$year++) {
	# jours mois année
	for (my $jour=1;$jour<=31;$jour++) {
	  # Format : 1 avril 1980
	  foreach my $m (@month) {
	    my $content="$jour $m $year";
	    while ($fileContent=~/$content/) {
	      my $startingOffset = index $fileContent, $content;
	      my $endingOffset=$startingOffset+length($content);
	      $propagatedAnnotations{"T$i\tDate $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	      my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	    }
	  }
	  # Formats : 01/04/1980, 01/04/80, 01.04.1980, 01.04.80
	  for (my $mois=1;$mois<=12;$mois++) {
	    my $j=1; my $m=1; my $y=substr($year,2);
	    if ($jour<10) { $j="0".$jour; } else { $j=$jour; }
	    if ($mois<10) { $m="0".$mois; } else { $m=$mois; }
	    my $content="$j/$m/$year";
	    while ($fileContent=~/\Q$content\E/) {
	      my $startingOffset = index $fileContent, $content;
	      my $endingOffset=$startingOffset+length($content);
	      $propagatedAnnotations{"T$i\tDate $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	      my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	    }
	    $content="$j/$m/$y";
	    while ($fileContent=~/\Q$content\E/) {
	      my $startingOffset = index $fileContent, $content;
	      my $endingOffset=$startingOffset+length($content);
	      $propagatedAnnotations{"T$i\tDate $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	      my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	    }
	    $content="$j.$m.$year";
	    while ($fileContent=~/\Q$content\E/) {
	      my $startingOffset = index $fileContent, $content;
	      my $endingOffset=$startingOffset+length($content);
	      $propagatedAnnotations{"T$i\tDate $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	      my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	    }
	    $content="$j.$m.$y";
	    while ($fileContent=~/\Q$content\E/) {
	      my $startingOffset = index $fileContent, $content;
	      my $endingOffset=$startingOffset+length($content);
	      $propagatedAnnotations{"T$i\tDate $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	      my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	    }
	  }
	}
	# mois année
	foreach my $m (@month) {
	  my $content="$m $year";
	  while ($fileContent=~/$content/) {
	    my $startingOffset = index $fileContent, $content;
	    my $endingOffset=$startingOffset+length($content);
	    $propagatedAnnotations{"T$i\tDate $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	    my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	  }
	}
	# année
	while ($fileContent=~/$year/ && $fileContent!~/\d$year\d/) {
	  my $startingOffset = index $fileContent, $year;
	  my $endingOffset=$startingOffset+length($year);
	  $propagatedAnnotations{"T$i\tDate $startingOffset $endingOffset\t$year"}++; $i++; $addNb++; $fileContent=~s/$year/xxxx/;
	}
      }
      # âges, ne sont pas précédés des séquences suivantes : "dans", "depuis", "il y a"
      for (my $ans=10;$ans<=90;$ans++) {
	my $content="$ans ans";
	while ($fileContent=~/$content/ && $fileContent!~/(à|dans|depuis|il y a) $content/i) {
	  my $startingOffset = index $fileContent, $content;
	  my $endingOffset=$startingOffset+length($content);
	  $propagatedAnnotations{"T$i\tAge $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	  my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	}
      }
      for (my $ans=1;$ans<=9;$ans++) {
	my $content="$ans ans";
	while ($fileContent=~/$content/ && $fileContent!~/(à|dans|depuis|il y a) $content/i) {
	  my $startingOffset = index $fileContent, $content;
	  my $endingOffset=$startingOffset+length($content);
	  $propagatedAnnotations{"T$i\tAge $startingOffset $endingOffset\t$content"}++; $i++; $addNb++;
	  my $new=""; for (my $z=0;$z<length($content);$z++) { $new.="x"; } $fileContent=~s/$content/$new/;
	}
      }

      ###
      # Production of the final annotation file (combination of
      # existing annotations from $allExistingAnnotations with
      # propagated annotations from %propagatedAnnotations) and
      # deletion of temporary annotation file

      open(S,'>:utf8',$annotationFile);
      print S "$allExistingAnnotations";
      foreach my $entry (sort keys %propagatedAnnotations) { print S "$entry\n"; $nbAfterPropagation++; }
      close(S);

      unlink("$temporaryAnnotationFile");
      print STDERR "$addNb new annotations\n";

    }
  }


  print STDERR "Total number of annotations after propagation: ",$nbAfterPropagation+$nbExistingAnnotations," ($nbExistingAnnotations existing annotations and $nbAfterPropagation propagated ones)\n";

  # # Log file (starting file,total annotation number)
  # open (L,">>propagation.log");
  # print L "($opt_s\,",$nbAfterPropagation+$nbExistingAnnotations,")\n";
  # close(L);
  # system("cat $opt_r/*ann | wc");

}


sub annotations() {

  ###
  # Existing annotations from each *.ann file are saved in a hash
  # table %firstAnnotations (correspondence token/tag) if token's
  # length fits the defined threshold (minimum size)

  foreach my $ann (@directory) {

    # First, user's comment associated with annotations are parsed, in
    # order to localize annotations that must not be propagated (the
    # value of the comment is defined in the configuration file,
    # namely STOP)

    my %stop=();  # Hash table containing annotation ID to do not propagate
    open(E,'<:utf8',$ann);
    while (my $line=<E>) {
      chomp $line;
      if ($line=~/AnnotatorNotes (T\d+)\t$userCommentValue/) { $stop{$1}++; }
    }
    close(E);


    # Second, existing annotations of concepts are saved, except for
    # annotations that must not be propagated, as expressed by the
    # user's comment (previous step)

    my %ids=();
    open(E,'<:utf8',$ann);
    while (my $line=<E>) {
      chomp $line;

      # Only lines of annotation of concepts are processed (in order
      # to avoid propagation of user's comments from the
      # AnnotatorNotes field)

      if ($line=~/^T/ && $line!~/AnnotatorNotes/) {
	my ($id,$info,$token)=split(/\t/,$line);
	my ($tag,$start,$end)=split(/ /,$info);
	$ids{$id}=$token;
	if (length($token)>=$minimumSize && $tag!~/^$forbiddenTag$/ && $token!~/^$forbiddenToken$/ && !exists $stop{$id}) {
	  $firstAnnotations{$token}=$tag;
	  $globalFrequency{$token}++;
	}
      }
      elsif ($line=~/^A/) {
	# Attributes: value associated with a token
	my ($id,$info)=split(/\t/,$line);
	my ($type,$ref,$tag)=split(/ /,$info);
	$attributes{$ids{$ref}}=$tag if ($tag ne "");
	$types{$tag}=$type if ($type ne "" && $tag ne "");
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
