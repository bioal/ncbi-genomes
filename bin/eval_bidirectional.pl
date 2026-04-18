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

if (@ARGV != 2) {
    print STDERR $USAGE;
    exit 1;
}
my ($HUMAN_MOUSE, $MOUSE_HUMAN) = @ARGV;

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
    my $bit_score = $f[-4];
    my $orthology = $f[-3];
    my $grouped_orthology = $f[-2];
    my $paralogs = $f[-1];
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
    my $bit_score = $f[-4];
    my $orthology = $f[-3];
    my $grouped_orthology = $f[-2];
    my $paralogs = $f[-1];
    $REVERSE_BIT_SCORE{"${human_gene}\t${mouse_gene}"} = $bit_score;
    $REVERSE_ORTHOLOGY{"${human_gene}\t${mouse_gene}"} = $orthology;
    $REVERSE_GROUPED_ORTHOLOGY{"${human_gene}\t${mouse_gene}"} = $grouped_orthology;
    $REVERSE_PARALOGS{"${human_gene}\t${mouse_gene}"} = $paralogs;
}
close(MOUSE_HUMAN);

my %HUMAN_GENE_PRINTED;
my %MOUSE_GENE_PRINTED;
my %HUMAN_ANCHOR_GENES;
my %MOUSE_ANCHOR_GENES;
my %ANCHOR_PAIR;
my @LINES = <STDIN>;
chomp(@LINES);
for my $line (@LINES) {
    my @f = split(/\t/, $line, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];
    my $human_mouse = "${human_gene}\t${mouse_gene}";
    if ($ORTHOLOGY{$human_mouse}         && $ORTHOLOGY{$human_mouse}         > 1 ||
        $REVERSE_ORTHOLOGY{$human_mouse} && $REVERSE_ORTHOLOGY{$human_mouse} > 1) {
        if ($HUMAN_ANCHOR_GENES{$human_gene}) {
            next;
        }
        if ($MOUSE_ANCHOR_GENES{$mouse_gene}) {
            next;
        }
        $ANCHOR_PAIR{"${human_gene}\t${mouse_gene}"} = 1;
        $HUMAN_ANCHOR_GENES{$human_gene} = 1;
        $MOUSE_ANCHOR_GENES{$mouse_gene} = 1;
        remeber_printed_genes($human_gene, \%HUMAN_GENE_PRINTED);
        remeber_printed_genes($mouse_gene, \%MOUSE_GENE_PRINTED);
    }
}

for my $line (@LINES) {
    my @f = split(/\t/, $line, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];
    if ($ANCHOR_PAIR{"${human_gene}\t${mouse_gene}"}) {
        print_result($human_gene, $mouse_gene);
    }
}

################################################################################
### Function ###################################################################
################################################################################

sub print_result {
    my ($human_gene, $mouse_gene) = @_;

    my $human_mouse = "${human_gene}\t${mouse_gene}";
    if ($PARALOGS{$human_mouse}) {
        my @human_paralogs = filter_human_paralogs($PARALOGS{$human_mouse}, $mouse_gene);
        if (@human_paralogs) {
            $human_gene = join(",", $human_gene, @human_paralogs);
        }
    }
    if ($REVERSE_PARALOGS{$human_mouse}) {
        my @mouse_paralogs = filter_mouse_paralogs($REVERSE_PARALOGS{$human_mouse}, $human_gene);
        if (@mouse_paralogs) {
            $mouse_gene = join(",", $mouse_gene, @mouse_paralogs);
        }
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

sub filter_human_paralogs {
    my ($genes, $anchor) = @_;

    my @genes = split(/,/, $genes);
    my @paralogs;
    for my $gene (@genes) {
        if ($REVERSE_ORTHOLOGY{"${gene}\t${anchor}"} && $REVERSE_ORTHOLOGY{"${gene}\t${anchor}"} > 1) {
            if (! includes_printed_genes($gene, \%HUMAN_GENE_PRINTED)) {
                push(@paralogs, $gene);
            }
        }
    }
    return @paralogs;
}

sub filter_mouse_paralogs {
    my ($genes, $anchor) = @_;

    my @genes = split(/,/, $genes);
    my @paralogs;
    for my $gene (@genes) {
        if ($ORTHOLOGY{"${anchor}\t${gene}"} && $ORTHOLOGY{"${anchor}\t${gene}"} > 1) {
            if (! includes_printed_genes($gene, \%MOUSE_GENE_PRINTED)) {
                push(@paralogs, $gene);
            }
        }
    }
    return @paralogs;
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
