#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM MAPPING_FILE...
";

my %OPT;
getopts('', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my %MAPPING;
for my $mapping_file (@ARGV) {
    if (!-f $mapping_file) {
        print STDERR "File not found: $mapping_file\n";
        exit 1;
    }
    read_mapping_file($mapping_file, \%MAPPING);
}

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
    if (!$MAPPING{$refseq1}) {
        print STDERR "Warning: RefSeq accession $refseq1 not found in mapping file.\n";
        next;  # Skip if refseq1 is not found
    }
    if (!$MAPPING{$refseq2}) {
        print STDERR "Warning: RefSeq accession $refseq2 not found in mapping file.\n";
        next;  # Skip if refseq2 is not found
    }
    my $geneid1 = $MAPPING{$refseq1};
    my $geneid2 = $MAPPING{$refseq2};
    print join("\t", $geneid1, $geneid2, @f), "\n";
}

################################################################################
### Function ###################################################################
################################################################################

sub read_mapping_file {
    my ($file, $r_mapping) = @_;
    open(my $fh, '<', $file) or die "Cannot open file $file: $!";
    while (<$fh>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        if (@f != 2) {
            die "Error: Expected 2 columns in mapping file, found " . scalar(@f) . " columns.\n";
        }
        my $geneid = $f[0];
        my $refseq = $f[1];
        if ($r_mapping->{$refseq}) {
            die "Error: Duplicate RefSeq accession found: $refseq for gene ID $r_mapping->{$refseq} and $geneid.\n";
        }
        $r_mapping->{$refseq} = $geneid;
    }
    close($fh);
}
