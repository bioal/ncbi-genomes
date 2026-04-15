#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-f: output only false
-t: output only true
-1: compare with ncbi_orthologs
-2: compare with curated orthologs
-3: compare with both
";

my %OPT;
getopts('ft123', \%OPT);

my %SYMBOL;
read_gene_info(
    "/home/chiba/github/hchiba1/human-mouse/ncbi_orthologs/gene_info.2026-04-02",
    \%SYMBOL);

my $REFERENCE = "/home/chiba/github/hchiba1/human-mouse/ncbi_orthologs/human-mouse.2026-04-02";
my $REFERENCE2 = "/home/chiba/github/dbcls/ncbigene-rdf/data/mouse/human_mouse.orthologs";
my %REF;
my %REF2;
read_reference($REFERENCE, \%REF);
read_reference_multi_genes($REFERENCE2, \%REF2);

my $COUNT_ALL = 0;
my $COUNT_BOTH = 0;
my $COUNT_NCBI = 0;
my $COUNT_SUMMARY = 0;
my $COUNT_MATCH_SYMBOLS = 0;
my $COUNT_FALSE = 0;
while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $comparison = eval_results(\%REF, $gene1, $gene2);
    my $comparison2 = eval_results(\%REF2, $gene1, $gene2);
    $COUNT_ALL++;
    if ($OPT{3}) {
        if ($comparison eq "true" && $comparison2 eq "true") {
            print $_, "\t", "both", "\n" if !$OPT{f};
            $COUNT_BOTH++;
        } elsif ($comparison eq "true") {
            print $_, "\t", "ncbi_orthologs", "\n" if !$OPT{f};
            $COUNT_NCBI++;
        } elsif ($comparison2 eq "true") {
            print $_, "\t", "curated", "\n" if !$OPT{f};
            $COUNT_SUMMARY++;
        } else {
            my $match3 = match_symbols($gene1, $gene2, \%SYMBOL);
            if ($match3) {
                print $_, "\t", "symbols_match", "\n" if !$OPT{f};
                $COUNT_MATCH_SYMBOLS++;
            } else {
                print $_, "\t", "false", "\n" if !$OPT{f};
                my @symbols1 = get_symbols($gene1);
                my @symbols2 = get_symbols($gene2);
                print $_, "\t@symbols1\t@symbols2\n" if $OPT{f};
                $COUNT_FALSE++;
            }
        }
        next;
    }
    if ($OPT{2}) {
        $comparison = $comparison2;
    }
    if ($OPT{f}) {
        if ($comparison eq "false") {
            print $_, "\n";
        }
    } elsif ($OPT{t}) {
        if ($comparison eq "true") {
            print $_, "\n";
        }
    } else {
        print $_, "\t", $comparison, "\n";
    }
}
my $RATE = sprintf("%.2f", ($COUNT_BOTH + $COUNT_NCBI + $COUNT_SUMMARY + $COUNT_MATCH_SYMBOLS) / $COUNT_ALL * 100);
print STDERR "ncbi:\t", $COUNT_BOTH + $COUNT_NCBI, "\n";
print STDERR "text:\t", $COUNT_BOTH + $COUNT_SUMMARY, "\n";
print STDERR "union:\t", $COUNT_BOTH + $COUNT_NCBI + $COUNT_SUMMARY, "\n";
print STDERR "match:\t", $COUNT_BOTH + $COUNT_NCBI + $COUNT_SUMMARY + $COUNT_MATCH_SYMBOLS, "\n";
print STDERR "undef:\t", $COUNT_FALSE, "\n";
print STDERR "all:\t", $COUNT_ALL, "\n";
print STDERR "rate:\t", $RATE, "\%\n";

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

sub read_reference {
    my ($file, $r_hash) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $gene1 = $f[0];
        my $gene2 = $f[1];
        ${$r_hash}{"${gene1}\t${gene2}"} = 1;
    }
    close(FILE);
}

sub read_reference_multi_genes {
    my ($file, $r_hash) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $genes1 = $f[0];
        my $gene2 = $f[1];
        my @genes1 = split(/,/, $genes1);
        for my $gene1 (@genes1) {
            ${$r_hash}{"${gene1}\t${gene2}"} = 1;
        }
    }
    close(FILE);
}

sub read_gene_info {
    my ($file, $r_hash) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $geneid = $f[1];
        my $symbol = $f[2];
        ${$r_hash}{$geneid} = $symbol;
    }
    close(FILE);

    return 0;
}

sub match_symbols {
    my ($genes1, $genes2, $r_symbol) = @_;

    my @symbols1 = get_symbols($genes1);
    my @symbols2 = get_symbols($genes2);
    for my $symbol1 (@symbols1) {
        for my $symbol2 (@symbols2) {
            if ($symbol1 eq uc($symbol2)) {
                return 1;
            } else {
                return 0;
            }
        }
    }
}

sub get_symbols {
    my ($genes) = @_;

    my @symbols;
    foreach my $gene (split(/,/, $genes)) {
        if ($SYMBOL{$gene}) {
            push(@symbols, $SYMBOL{$gene});
        }
    }

    return @symbols;
}
