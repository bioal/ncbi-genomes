#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
get A-class (LOES > 0.5 and exact match with NCBI orthologs or summary text)
-b: B-class (LOES > 0.5 and confirmed by other references)
-p: P-class (special case of non-coding RNA)
-q: Q-class (LOES > 0.5 but not confirmed by references)
";

my %OPT;
getopts('bpq', \%OPT);

while (<>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $geneid2 = $f[1];
    my $orthology = $f[6];
    my $confirmed = $f[-1];
    if ($orthology > 0.5) {
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
        # confirm by NCBI orthologs or summary text
        if ($geneid2 eq "118568407") {
            print join("\t", @f[0..6,10..$#f]), "\n" if $OPT{p};
        } elsif ($confirmed eq "false") {
            print join("\t", @f[0..6,10..$#f]), "\n" if $OPT{q};
        } elsif ($confirmed =~ /[NT]/) {
            print join("\t", @f[0..6,10..$#f]), "\n" if !$OPT{p} and !$OPT{q} and !$OPT{b};
        } else {
            print join("\t", @f[0..6,10..$#f]), "\n" if $OPT{b};
        }
    }
}
