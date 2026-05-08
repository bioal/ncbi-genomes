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

my %REF_LINE;
read_references($ARGV[0], \%REF_LINE);

while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    if ($REF_LINE{"${gene1}\t${gene2}"}) {
        print $_, "\t", $REF_LINE{"${gene1}\t${gene2}"}, "\n" if ! $OPT{f};
    } else {
        print $_, "\n" if $OPT{f};
    }
}

################################################################################
### Function ###################################################################
################################################################################

sub read_references {
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
