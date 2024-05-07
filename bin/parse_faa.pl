#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM GENE2REFSEQ
";

my %OPT;
getopts('', \%OPT);

!@ARGV || -t and die $USAGE;

my ($GENE2REFSEQ) = @ARGV;
open(GENE2REFSEQ, "$GENE2REFSEQ") || die "$!";
my %PROT2GENE = ();
while (<GENE2REFSEQ>) {
    chomp;
    if (/^#/) {
        next;
    }
    my @f = split("\t", $_, -1);
    if (@f != 16) {
        die "invalid format: $_";
    }
    my $gene_id = $f[1];
    my $protein = $f[5];
    if ($protein eq "-") {
        next;
    }
    $protein =~ s/\.\d+$//;
    if ($PROT2GENE{$protein}) {
        if ($PROT2GENE{$protein} ne $gene_id) {
            die "multiple gene_id for $protein: $PROT2GENE{$protein} and $gene_id";
        }
    } else {
        $PROT2GENE{$protein} = $gene_id;
    }
}
close(GENE2REFSEQ);

my $ID = "";
my $SEQ = "";
while (<STDIN>) {
    chomp;
    if (/^>(\S+)/) {
        my $id = $1;
        print_previous_seq_length();
        $ID = $id;
        $SEQ = "";
    } else {
        $SEQ .= $_;
    }
}
print_previous_seq_length();

################################################################################
### Function ###################################################################
################################################################################

sub print_previous_seq_length {
    if ($SEQ) {
        my $len = length($SEQ);
        my $gene_id = "";
        my $protein = $ID;
        $protein =~ s/\.\d+$//;
        if ($PROT2GENE{$protein}) {
            $gene_id = $PROT2GENE{$protein};
        } else {
            die "no gene_id for $ID";
        }
        print "$gene_id\t$ID\t$len\n";
    }
}
