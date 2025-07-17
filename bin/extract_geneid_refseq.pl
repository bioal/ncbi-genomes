#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-v: refseq with version
";

my %OPT;
getopts('v', \%OPT);

my %TARGET_TAX;
for my $taxid (@ARGV) {
    if ($taxid =~ /^\d+$/) {
        $TARGET_TAX{$taxid} = 1;
    } else {
        print STDERR "Invalid taxid: $taxid\n";
        exit 1;
    }
}

my %hash;
while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    if (@f != 16) {
        die;
    }
    if (/^#/) {
        next;  # Skip header lines
    }
    my $taxid = $f[0];
    my $geneid = $f[1];
    my $refseq = $f[5];
    if (%TARGET_TAX && !$TARGET_TAX{$taxid}) {
        next;
    }
    if ($refseq eq '-') {
        next;  # Skip if no RefSeq accession
    }
    if (!$OPT{v} && $refseq =~ /^(\S+)\.(\d+)$/) {
        $refseq = $1;
    }
    if ($hash{"$geneid\t$refseq"}) {
        next;  # Skip duplicates
    }
    $hash{"$geneid\t$refseq"} = 1;
    print "$geneid\t$refseq\n";
}
