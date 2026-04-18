#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: cat TABLE | $PROGRAM REFERENCE_TABLE
-f: only false
";

my %OPT;
getopts('f', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my %RESULT;
read_results($ARGV[0], \%RESULT);

while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    if ($OPT{f}) {
        if (!$RESULT{"${gene1}\t${gene2}"}) {
            print $_,  "\n";
        }
    } else {
        if ($RESULT{"${gene1}\t${gene2}"}) {
            print $_;
            print "\t";
            print $RESULT{"${gene1}\t${gene2}"};
            print "\n";
        }
    }
}

################################################################################
### Function ###################################################################
################################################################################

sub read_results {
    my ($file, $r_hash) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $genes1 = $f[0];
        my $genes2 = $f[1];
        my @genes1 = split(/,/, $genes1);
        my @genes2 = split(/,/, $genes2);
        foreach my $gene1 (@genes1) {
            foreach my $gene2 (@genes2) {
                ${$r_hash}{"${gene1}\t${gene2}"} = $_;
            }
        }
    }
    close(FILE);
}
