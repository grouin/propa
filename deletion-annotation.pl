#!/usr/bin/perl

# Delete annotations in *.ann files based on the
# "deletion-lexicon.txt" list.

# Usage: perl deletion-annotation.pl -r data/propagation -s xaa


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

my %stop=();                   # Existing annotations that must be deleted
my $blackCategory="token";   # Category we want to remove from all annotations files



###
# Program

configuration();
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
      print STDERR "Processing $annotationFile\n";

      # Temporary file for the annotation file
      my $temporaryAnnotationFile=$annotationFile; $temporaryAnnotationFile=~s/ann$/tmp/;
      copy("$annotationFile","$temporaryAnnotationFile");
      my $allExistingAnnotations="";

      # Reading of existing annotations
      open(E,$temporaryAnnotationFile);
      while (my $ligne=<E>) {
	chomp $ligne;
	my @cols=split(/\t/,$ligne);
	if (!exists $stop{$cols[2]} && $cols[1]!~/^$blackCategory /) {
	  $allExistingAnnotations.="$ligne\n";
	} else {
	  warn "$cols[2] found in $ligne\n";
	}
      }
      close(E);


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


}

sub configuration() {

  ###
  # Script general configuration

  open(E,"deletion-lexicon.txt") or die "Configuration file not found.\n";
  while (my $line=<E>) {
    chomp $line;
    $stop{$line}++;
  }
  close(E);

}
