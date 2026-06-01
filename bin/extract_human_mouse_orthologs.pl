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
    if ($f[0] eq "9606" && $f[3] eq "10090") {
        print "$f[1]\t$f[4]\n";
    }
    if ($f[0] eq "10090" && $f[3] eq "9606") {
        print "$f[4]\t$f[1]\n";
    }
}
