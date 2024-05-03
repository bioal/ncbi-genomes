#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

my %OPT;
getopts('', \%OPT);

while (<>) {
    chomp;
    if (/^#/) {
        next;
    }
    my @f = split(/\t/, $_, -1);
    if (@f != 38) {
        die $_;
    }
    if ($f[24] =~ /vertebrate|plant|fungi|protozoa/) {
        print "$_\n";
    } elsif ($f[24] =~ /bacteria|archaea|viral/) {
    } else {
        die $_;
    }
}
