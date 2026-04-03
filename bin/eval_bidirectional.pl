#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-a: output all pairs, not just bidirectional best hits
-s: silent mode for testing
";

my %OPT;
getopts('as', \%OPT);

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
my %MIN_ORTHOLOGY;
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
    if ($ORTHOLOGY{"${human_gene}\t${mouse_gene}"}) {
        my $human_mouse_orthology = $ORTHOLOGY{"${human_gene}\t${mouse_gene}"};
        $MIN_ORTHOLOGY{"${human_gene}\t${mouse_gene}"} = min($human_mouse_orthology, $orthology);
    }
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
    if (!$OPT{a}) {
        if ($HUMAN_GENE_PRINTED{$human_gene} || $MOUSE_GENE_PRINTED{$mouse_gene}) {
            next;
        }
    }

    if (insufficient_orthology($human_gene, $mouse_gene)) {
        next;
    }
    if (! $OPT{s}) {
        print_result($human_gene, $mouse_gene);
    }
    $HUMAN_GENE_PRINTED{$human_gene} = 1;
    $MOUSE_GENE_PRINTED{$mouse_gene} = 1;
}
close(BIT_SCORES);

################################################################################
### Function ###################################################################
################################################################################

sub insufficient_orthology {
    my ($human_gene, $mouse_gene) = @_;
    my $human_mouse = "${human_gene}\t${mouse_gene}";

    # hit exists in both directions, but both have orthology <= 1
    if ($REVERSE_BIT_SCORE{$human_mouse} &&
        $REVERSE_ORTHOLOGY{$human_mouse} <= 1 &&
        $BIT_SCORE{$human_mouse} &&
        $ORTHOLOGY{$human_mouse} <= 1 ) {
        return 1;
    }

    # hit does not exist in one direction, and the other direction has orthology <= 1
    if (! $BIT_SCORE{$human_mouse} &&
          $REVERSE_ORTHOLOGY{$human_mouse} <= 1) {
        return 1;
    }
    if (! $REVERSE_BIT_SCORE{$human_mouse} &&
          $ORTHOLOGY{$human_mouse} <= 1 ) {
        return 1;
    }

    # hit exists in both directions, but both have orthology <= 1 and grouped orthology <= 0.9
    if ($ORTHOLOGY{$human_mouse}   && $ORTHOLOGY{$human_mouse}   <= 1 &&
        $REVERSE_ORTHOLOGY{$human_mouse}   && $REVERSE_ORTHOLOGY{$human_mouse}   <= 1 &&
        $GROUPED_ORTHOLOGY{$human_mouse} && $GROUPED_ORTHOLOGY{$human_mouse} <= 0.9 &&
        $REVERSE_GROUPED_ORTHOLOGY{$human_mouse} && $REVERSE_GROUPED_ORTHOLOGY{$human_mouse} <= 0.9
        ) {
        return 1;
    }
    return 0;
}

sub print_result {
    my ($human_gene, $mouse_gene) = @_;
    my $human_mouse = "${human_gene}\t${mouse_gene}";
    if ($PARALOGS{$human_mouse}) {
        $human_gene .= "," . $PARALOGS{$human_mouse};
    }
    if ($REVERSE_PARALOGS{$human_mouse}) {
        $mouse_gene .= "," . $REVERSE_PARALOGS{$human_mouse};
    }
    print join("\t",
               $human_gene,
               $mouse_gene,
               $BIT_SCORE{$human_mouse} || 0,
               $REVERSE_BIT_SCORE{$human_mouse} || 0,
               $ORTHOLOGY{$human_mouse} || 0,
               $REVERSE_ORTHOLOGY{$human_mouse} || 0,
               $MIN_ORTHOLOGY{$human_mouse} || 0,
               $GROUPED_ORTHOLOGY{$human_mouse} || 0,
               $REVERSE_GROUPED_ORTHOLOGY{$human_mouse} || 0,
               min($GROUPED_ORTHOLOGY{$human_mouse} || 0, $REVERSE_GROUPED_ORTHOLOGY{$human_mouse} || 0)
        ), "\n";
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
