#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-p: only protein-coding genes
-d: only different symbols
-s: only same symbols
-t: output type of genes
";

my %OPT;
getopts('pdst', \%OPT);

my %INFO;
read_gene_info(
    "/home/chiba/github/hchiba1/human-mouse/ncbi_orthologs/gene_info.2026-04-02",
    \%INFO
    );

while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $symbol1 = $INFO{symbol}{$gene1} || die "No symbol for $gene1";
    my $symbol2 = $INFO{symbol}{$gene2} || die "No symbol for $gene2";
    my $type1 = $INFO{type}{$gene1} || die "No type for $gene1";
    my $type2 = $INFO{type}{$gene2} || die "No type for $gene2";
    
    if ($OPT{p}) {
        if ($type1 ne "protein-coding" || $type2 ne "protein-coding") {
            next;
        }
    }
    if ($OPT{d}) {
        if ($symbol1 eq uc($symbol2)) {
            next;
        }
    }
    if ($OPT{s}) {
        if ($symbol1 ne uc($symbol2)) {
            next;
        }
    }
    print $_;
    print "\t$symbol1\t$symbol2";
    if ($OPT{t}) {
        print "\t$type1\t$type2";
    }
    print "\n";
}

################################################################################
### Function ###################################################################
################################################################################

sub read_gene_info {
    my ($file, $r_info) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $geneid = $f[1];
        my $symbol = $f[2];
        my $type = $f[9];
        ${$r_info}{symbol}{$geneid} = $symbol;
        ${$r_info}{type}{$geneid} = $type;
    }
    close(FILE);

    return 0;
}
