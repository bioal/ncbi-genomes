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

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my $N_FILES = @ARGV;

my %HASH;
for (my $i = 0; $i < $N_FILES; $i++) {
    my $file = $ARGV[$i];
    read_file($file, $i + 1, \%HASH);
}

while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    print $_;
    for (my $idx = 1; $idx <= $N_FILES; $idx ++) {
        my $comparison = eval_results($HASH{$idx}, $gene1, $gene2);
        print "\t$comparison";
    }
    print "\n";
}

################################################################################
### Function ###################################################################
################################################################################
sub eval_results {
    my ($r_hash, $genes1, $genes2) = @_;

    my @genes1 = split(/,/, $genes1);
    my @genes2 = split(/,/, $genes2);
    foreach my $gene1 (@genes1) {
        foreach my $gene2 (@genes2) {
            if (${$r_hash}{"${gene1}\t${gene2}"}) {
                return "true";
            }
        }
    }
    return "false";
}

sub match_results {
    my ($r_hash, $gene1, $gene2) = @_;

    if (${$r_hash}{"${gene1}\t${gene2}"}) {
        return "true";
    } else {
        return "false";
    }
}

sub read_file {
    my ($file, $index, $r_hash) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $gene1 = $f[0];
        my $gene2 = $f[1];
        ${$r_hash}{$index}{"${gene1}\t${gene2}"} = 1;
    }
    close(FILE);
}
