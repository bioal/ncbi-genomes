#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM TAXON...
";

my %OPT;
getopts('', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my %TAXON;

for my $arg (@ARGV) {
    if ($arg eq "human") {
        $TAXON{"9606"} = 1;
    } elsif ($arg eq "mouse") {
        $TAXON{"10090"} = 1;
    } else {
        $TAXON{$arg} = 1;
    }
}

while (<STDIN>) {
    chomp;
    if (/^##  /) {
        next;
    }
    if (/^#/) {
        print "$_\n";
    }
    my @f = split(/\t/, $_, -1);
    if ($TAXON{$f[0]}) {
        print "$_\n";
    }
}
