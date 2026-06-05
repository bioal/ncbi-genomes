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
    my @f = split(/\t/, $_, -1);
    my $orthology = $f[6];
    my $confirmed = $f[10];
    if ($orthology > 0.5) {
        if ($confirmed =~ /[NT]/) {
            print "$_\n";
        }
    }
}
