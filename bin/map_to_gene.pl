#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM MAPPING_FILE
";

my %OPT;
getopts('', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($MAPPING_FILE) = @ARGV;

my %HASH;
open(MAPPING_FILE, "$MAPPING_FILE") || die "$!";
while (<MAPPING_FILE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    if (@f != 2) {
        die "Error: Expected 2 columns in mapping file, found " . scalar(@f) . " columns.\n";
    }
    my $geneid = $f[0];
    my $refseq = $f[1];
    if ($HASH{$refseq}) {
        die "Error: Duplicate RefSeq accession found: $refseq for gene ID $HASH{$refseq} and $geneid.\n";
    }
    $HASH{$refseq} = $geneid;
}
close(MAPPING_FILE);

while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $refseq1 = shift @f;
    my $refseq2 = shift @f;
    if ($refseq1 =~ /^(\S+)\.(\d+)$/) {
        $refseq1 = $1;  # Remove version number if present
    }
    if ($refseq2 =~ /^(\S+)\.(\d+)$/) {
        $refseq2 = $1;  # Remove version number if present
    }
    if (!$HASH{$refseq1}) {
        print STDERR "Warning: RefSeq accession $refseq1 not found in mapping file.\n";
        next;  # Skip if refseq1 is not found
    }
    if (!$HASH{$refseq2}) {
        print STDERR "Warning: RefSeq accession $refseq2 not found in mapping file.\n";
        next;  # Skip if refseq2 is not found
    }
    my $geneid1 = $HASH{$refseq1};
    my $geneid2 = $HASH{$refseq2};
    print join("\t", $geneid1, $geneid2, @f), "\n";
}
