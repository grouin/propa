#!/usr/bin/perl

# Conserve les annotations imbriquées de même taille (deux annotations
# sur la même portion), conserve l'annotation la plus longue parmi
# deux annotations imbriquées ayant le même début, et supprime les
# annotations dans les URLs

# Usage: perl supprime-annotations-imbriquees.pl -r data/propagation -s xaa


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




###
# Program

dossier();



###
# Sub-program

sub dossier() {

  ###
  # For each file from the directory, annotation deletion starts
  # when file to process corresponds to the starting file ($flag==1)

  my $flag=0;
  my ($k,$l)=(0,0);

  foreach my $annotationFile (@directory) {

    ###
    # Contrôle du texte et début des URLs
    my $texte=$annotationFile; $texte=~s/ann$/txt/;
    my ($i,$j)=(0,0);
    open(E,$texte);
    while (my $ligne=<E>) {
      chomp $ligne;
      if ($ligne=~/^(.*)(http[^\s]+)/) { $i=length($1); $j=$i+length($2); }
    }
    close(E);
    ###


    my %deja=();
    my %deja2=();
    my %lignesExistantes=();

    # Annotation propagation starts if starting file is found
    if ($annotationFile=~/$startingFile/) { $flag=1; }
    if ($flag==1) {
      print STDERR "Processing $annotationFile\n";

      # Temporary file for the annotation file
      my $temporaryAnnotationFile=$annotationFile; $temporaryAnnotationFile=~s/ann$/tmp/;
      copy("$annotationFile","$temporaryAnnotationFile");
      my $allExistingAnnotations="";


      # Reading of existing annotations
      open(E,$temporaryAnnotationFile);
      while (my $ligne=<E>) {
	chomp $ligne;
	# T3      food 796 812    Grapefruit juice
	my ($id,$annotations,$portion)=split(/\t/,$ligne);
	my ($annotation,$offsetDeb,$offsetFin)=split(/ /,$annotations);

	# Clé = offset de début, valeur = ligne complète
	if (exists $deja{$offsetDeb}) {
	  # on remplace une valeur existante si la nouvelle valeur est plus longue
	  if (length($ligne) > length($deja{$offsetDeb})) {
	    # sauf si hashtag imbriqué : on conserve
	    if ($annotation=~/hashtag/ || $deja{$offsetDeb}=~/hashtag/) { $deja{$offsetDeb}.="§$ligne"; }
	    # sinon : on remplace
	    else {
	      warn "*** modifie $ligne (",length($ligne)," car.) vs. $deja{$offsetDeb} (",length($deja{$offsetDeb})," car.)\n";
	      $deja{$offsetDeb}="$ligne"; }
	  }
	  # mais si la longueur est la même, on conserve les deux
	  elsif (length($ligne)==length($deja{$offsetDeb})) { $deja{$offsetDeb}.="§$ligne"; }
	}
	# sinon, on mémorise l'annotation
	else { $deja{$offsetDeb}="$ligne"; }

      
	# # Clé = offset de fin, valeur = ligne complète
	# if (exists $deja2{$offsetFin}) {
	#   # on remplace une valeur existante si la nouvelle valeur est plus longue
	#   if (length($ligne) > length($deja2{$offsetFin})) {
	#     # sauf si hashtag imbriqué : on conserve
	#     if ($annotation=~/hashtag/ || $deja2{$offsetFin}=~/hashtag/) { $deja2{$offsetFin}.="§$ligne"; }
	#     # sinon : on remplace
	#     else {
	#       warn "*** modifie $ligne (",length($ligne)," car.) vs. $deja2{$offsetFin} (",length($deja2{$offsetFin})," car.)\n";
	#       $deja2{$offsetFin}="$ligne"; }
	#   }
	#   # mais si la longueur est la même, on conserve les deux
	#   elsif (length($ligne)==length($deja2{$offsetFin})) { $deja2{$offsetFin}.="§$ligne"; }
	# }
	# # sinon, on mémorise l'annotation
	# else { $deja2{$offsetFin}="$ligne"; }



	$k++ if ($ligne=~/^T/);
      }
      close(E);

      foreach my $offsetDeb (sort keys %deja) {
	if ((($offsetDeb<=$i) || ($offsetDeb>$j)) && !exists $lignesExistantes{$deja{$offsetDeb}}) {
	  $allExistingAnnotations.="$deja{$offsetDeb}\n";
	  $l++;
	}
	$lignesExistantes{$deja{$offsetDeb}}++;
      }
      # foreach my $offsetFin (sort keys %deja2) {
      # 	if (!exists $lignesExistantes{$deja2{$offsetFin}}) {
      # 	  $allExistingAnnotations.="$deja2{$offsetFin}\n";
      # 	  $l++;
      # 	}
      # 	$lignesExistantes{$deja2{$offsetFin}}++;
      # }
      $allExistingAnnotations=~s/§/\n/g;

      ###
      # Production of the final annotation file (existing annotations
      # from $allExistingAnnotations, except annotations that must be
      # deleted) and deletion of temporary annotation file

      open(S,">$annotationFile");
      print S "$allExistingAnnotations";
      close(S);

      unlink("$temporaryAnnotationFile");

    }
  }

  warn "Out of $k existing annotations, only kept $l annotations\n";

}
