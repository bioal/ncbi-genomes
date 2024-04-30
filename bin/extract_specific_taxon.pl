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

my $KEY_COL = 0;
while (<STDIN>) {
    chomp;
    if (/^#+  /) {
        next;
    }
    my @f = split(/\t/, $_, -1);
    if (/^#/) {
        print "$_\n";
        for (my $i=0; $i<@f; $i++) {
            if ($f[$i] eq "taxid") {
                $KEY_COL = $i;
                last;
            }
        }
    }
    if ($TAXON{$f[$KEY_COL]}) {
        print "$_\n";
    }
}
