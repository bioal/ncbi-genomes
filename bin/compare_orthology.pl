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
        my $comparison = "false";
        if ($HASH{$idx}{"${gene1}\t${gene2}"}) {
            $comparison = "true";
        }
        print "\t$comparison";
    }
    print "\n";
}

################################################################################
### Function ###################################################################
################################################################################
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
