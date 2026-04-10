#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-s: silent mode for testing
";

my %OPT;
getopts('s', \%OPT);

if (@ARGV != 3) {
    print STDERR $USAGE;
    exit 1;
}
my ($HUMAN_MOUSE, $MOUSE_HUMAN, $BIT_SCORES) = @ARGV;

my %BIT_SCORE;
my %ORTHOLOGY;
my %PARALOGS;
my %GROUPED_ORTHOLOGY;
open(HUMAN_MOUSE, "$HUMAN_MOUSE") || die "$!";
while (<HUMAN_MOUSE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];
    my $bit_score = $f[11];
    my $orthology = $f[12];
    my $grouped_orthology = $f[13];
    my $paralogs = $f[14];
    $BIT_SCORE{"${human_gene}\t${mouse_gene}"} = $bit_score;
    $ORTHOLOGY{"${human_gene}\t${mouse_gene}"} = $orthology;
    $GROUPED_ORTHOLOGY{"${human_gene}\t${mouse_gene}"} = $grouped_orthology;
    $PARALOGS{"${human_gene}\t${mouse_gene}"} = $paralogs;
}
close(HUMAN_MOUSE);

my %REVERSE_BIT_SCORE;
my %REVERSE_ORTHOLOGY;
my %REVERSE_PARALOGS;
my %REVERSE_GROUPED_ORTHOLOGY;
open(MOUSE_HUMAN, "$MOUSE_HUMAN") || die "$!";
while (<MOUSE_HUMAN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $mouse_gene = $f[0];
    my $human_gene = $f[1];
    my $bit_score = $f[11];
    my $orthology = $f[12];
    my $grouped_orthology = $f[13];
    my $paralogs = $f[14];
    $REVERSE_BIT_SCORE{"${human_gene}\t${mouse_gene}"} = $bit_score;
    $REVERSE_ORTHOLOGY{"${human_gene}\t${mouse_gene}"} = $orthology;
    $REVERSE_GROUPED_ORTHOLOGY{"${human_gene}\t${mouse_gene}"} = $grouped_orthology;
    $REVERSE_PARALOGS{"${human_gene}\t${mouse_gene}"} = $paralogs;
}
close(MOUSE_HUMAN);

my %HUMAN_GENE_PRINTED;
my %MOUSE_GENE_PRINTED;
open(BIT_SCORES, "$BIT_SCORES") || die "$!";
while (<BIT_SCORES>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];
    my $human_mouse = "${human_gene}\t${mouse_gene}";
    if ($ORTHOLOGY{$human_mouse}         && $ORTHOLOGY{$human_mouse}         > 1 ||
        $REVERSE_ORTHOLOGY{$human_mouse} && $REVERSE_ORTHOLOGY{$human_mouse} > 1) {
        print_result($human_gene, $mouse_gene);
    }
}
close(BIT_SCORES);

################################################################################
### Function ###################################################################
################################################################################

sub print_result {
    my ($human_gene, $mouse_gene) = @_;

    my $human_mouse = "${human_gene}\t${mouse_gene}";
    if ($PARALOGS{$human_mouse}) {
        $human_gene .= "," . $PARALOGS{$human_mouse};
    }
    if ($REVERSE_PARALOGS{$human_mouse}) {
        $mouse_gene .= "," . $REVERSE_PARALOGS{$human_mouse};
    }
    if (includes_printed_genes($human_gene, \%HUMAN_GENE_PRINTED)) {
        return;
    }
    if (includes_printed_genes($mouse_gene, \%MOUSE_GENE_PRINTED)) {
        return;
    }
    if (! $OPT{s}) {
        print join("\t",
                   $human_gene,
                   $mouse_gene,
                   $BIT_SCORE{$human_mouse} || 0,
                   $REVERSE_BIT_SCORE{$human_mouse} || 0,
                   $ORTHOLOGY{$human_mouse} || 0,
                   $REVERSE_ORTHOLOGY{$human_mouse} || 0,
                   min($ORTHOLOGY{$human_mouse} || 0, $REVERSE_ORTHOLOGY{$human_mouse} || 0),
                   $GROUPED_ORTHOLOGY{$human_mouse} || 0,
                   $REVERSE_GROUPED_ORTHOLOGY{$human_mouse} || 0,
                   min($GROUPED_ORTHOLOGY{$human_mouse} || 0, $REVERSE_GROUPED_ORTHOLOGY{$human_mouse} || 0)
            ), "\n";
    }
    remeber_printed_genes($human_gene, \%HUMAN_GENE_PRINTED);
    remeber_printed_genes($mouse_gene, \%MOUSE_GENE_PRINTED);
}

sub includes_printed_genes {
    my ($genes, $r_hash) = @_;

    my @genes = split(/,/, $genes);
    foreach my $gene (@genes) {
        if ($r_hash->{$gene}) {
            return 1;
        }
    }
    return 0;
}

sub remeber_printed_genes {
    my ($genes, $r_hash) = @_;

    my @genes = split(/,/, $genes);
    foreach my $gene (@genes) {
        $r_hash->{$gene} = 1;
    }
}

sub min {
    my ($a, $b) = @_;

    if ($a < $b) {
        return $a;
    }
    else {
        return $b;
    }
}
