#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM GENES(comma-separated or space-separated)
-s GENE: seed gene ID
";

my %OPT;
getopts('s:', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my $TARGET_GENES = join(",", @ARGV);
my $TARGET_SYMBOLS = get_symbols($TARGET_GENES);
my %TARGET_GENES;
for my $gene (split(/,/, $TARGET_GENES)) {
    $TARGET_GENES{$gene} = 1;
}

my %INFO;
read_gene_info(
    "/home/chiba/github/hchiba1/human-mouse/ncbi_orthologs/gene_info.2026-04-02",
    \%INFO);

my $SEED_GENE = $OPT{s};
my $SEED_GENE_SYMBOL = get_symbols($SEED_GENE);

while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $genes1 = $f[0];
    my $genes2 = $f[1];
    if (includes_target_gene($genes1, \%TARGET_GENES) || includes_target_gene($genes2, \%TARGET_GENES)) {
        print $_, "\t", get_symbols($genes1), " - ", get_symbols($genes2), "\n";
    }
}

################################################################################
### Function ###################################################################
################################################################################

sub includes_target_gene {
    my ($genes, $r_target_genes) = @_;

    for my $gene (split(/,/, $genes)) {
        if (${$r_target_genes}{$gene}) {
            return 1;
        }
    }

    return 0;
}

sub read_gene_info {
    my ($file, $r_info) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $taxid = $f[0];
        my $geneid = $f[1];
        my $symbol = $f[2];
        ${$r_info}{$geneid}{symbol} = $symbol;
        ${$r_info}{$geneid}{taxid} = $taxid;
    }
    close(FILE);

    return 0;
}

sub get_symbols {
    my ($genes) = @_;

    my @symbols;
    foreach my $gene (split(/,/, $genes)) {
        if ($INFO{$gene} && $INFO{$gene}{symbol}) {
            my $symbol = $INFO{$gene}{symbol};
            if ($gene eq $SEED_GENE) {
                $symbol = "\e[91m$symbol\e[0m";
            } elsif ($TARGET_GENES{$gene}) {
                $symbol = "\e[38;5;45m$symbol\e[0m";
            }
            push(@symbols, $symbol);
        }
    }

    if (@symbols == 0) {
        return 0;
    } else {
        return join(",", @symbols);
    }
}
