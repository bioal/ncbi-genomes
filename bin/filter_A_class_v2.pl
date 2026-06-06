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
    my $confirmed = $f[-1];
    if ($orthology > 0.5) {
        if ($confirmed =~ /[NT]/) {
            my @f = split("\t", $_, -1);
            if ($f[4] ne $f[7]) {
                print STDERR "Error: $_\n";
                die;
            }
            if ($f[5] ne $f[8]) {
                print STDERR "Error: $_\n";
                die;
            }
            if ($f[6] ne $f[9]) {
                print STDERR "Error: $_\n";
                die;
            }
            print join("\t", @f[0..6,10..$#f]), "\n";
        }
    }
}
