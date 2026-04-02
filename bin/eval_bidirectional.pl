#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-a: output all pairs, not just bidirectional best hits
";

my %OPT;
getopts('a', \%OPT);

if (@ARGV != 3) {
    print STDERR $USAGE;
    exit 1;
}
my ($HUMAN_MOUSE, $MOUSE_HUMAN, $BIT_SCORES) = @ARGV;

my %HUMAN_MOUSE_BIT_SCORE;
my %HUMAN_MOUSE_ORTHOLOGY_SCORE;
my %HUMAN_MOUSE_ORTHOLOGY_SCORE_2;
open(HUMAN_MOUSE, "$HUMAN_MOUSE") || die "$!";
while (<HUMAN_MOUSE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];
    my $bit_score = $f[11];
    my $orthology_score = $f[12];
    my $orthology_score_2 = $f[13];
    $HUMAN_MOUSE_BIT_SCORE{"${human_gene}\t${mouse_gene}"} = $bit_score;
    $HUMAN_MOUSE_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"} = $orthology_score;
    $HUMAN_MOUSE_ORTHOLOGY_SCORE_2{"${human_gene}\t${mouse_gene}"} = $orthology_score_2;
}
close(HUMAN_MOUSE);

my %MOUSE_HUMAN_BIT_SCORE;
my %MOUSE_HUMAN_ORTHOLOGY_SCORE;
my %MOUSE_HUMAN_ORTHOLOGY_SCORE_2;
my %MIN_ORTHOLOGY_SCORE;
open(MOUSE_HUMAN, "$MOUSE_HUMAN") || die "$!";
while (<MOUSE_HUMAN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $mouse_gene = $f[0];
    my $human_gene = $f[1];
    my $mouse_human_bit_score = $f[11];
    my $mouse_human_orthology_score = $f[12];
    my $mouse_human_orthology_score_2 = $f[13];
    $MOUSE_HUMAN_BIT_SCORE{"${human_gene}\t${mouse_gene}"} = $mouse_human_bit_score;
    $MOUSE_HUMAN_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"} = $mouse_human_orthology_score;
    $MOUSE_HUMAN_ORTHOLOGY_SCORE_2{"${human_gene}\t${mouse_gene}"} = $mouse_human_orthology_score_2;
    if ($HUMAN_MOUSE_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"}) {
        my $human_mouse_orthology_score = $HUMAN_MOUSE_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"};
        $MIN_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"} = min($human_mouse_orthology_score, $mouse_human_orthology_score);
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
    my $human_mouse = "${human_gene}\t${mouse_gene}";

    if ($MOUSE_HUMAN_BIT_SCORE{$human_mouse} &&
        $MOUSE_HUMAN_ORTHOLOGY_SCORE{$human_mouse} <= 1 &&
        $HUMAN_MOUSE_BIT_SCORE{$human_mouse} &&
        $HUMAN_MOUSE_ORTHOLOGY_SCORE{$human_mouse} <= 1 ) {
        # print_result($human_gene, $mouse_gene);
        next;
    }

    if (insufficient_orthology_score($human_mouse)) {
        next;
    }
    print_result($human_gene, $mouse_gene);
    $HUMAN_GENE_PRINTED{$human_gene} = 1;
    $MOUSE_GENE_PRINTED{$mouse_gene} = 1;
}
close(BIT_SCORES);

################################################################################
### Function ###################################################################
################################################################################

sub insufficient_orthology_score {
    my ($human_mouse) = @_;

    if (! $HUMAN_MOUSE_BIT_SCORE{$human_mouse} &&
          $MOUSE_HUMAN_ORTHOLOGY_SCORE{$human_mouse} <= 1) {
        return 1;
    }

    if (! $MOUSE_HUMAN_BIT_SCORE{$human_mouse} &&
          $HUMAN_MOUSE_ORTHOLOGY_SCORE{$human_mouse} <= 1 ) {
        return 1;
    }

    if ($HUMAN_MOUSE_ORTHOLOGY_SCORE{$human_mouse}   && $HUMAN_MOUSE_ORTHOLOGY_SCORE{$human_mouse}   <= 1 &&
        $MOUSE_HUMAN_ORTHOLOGY_SCORE{$human_mouse}   && $MOUSE_HUMAN_ORTHOLOGY_SCORE{$human_mouse}   <= 1 &&
        $HUMAN_MOUSE_ORTHOLOGY_SCORE_2{$human_mouse} && $HUMAN_MOUSE_ORTHOLOGY_SCORE_2{$human_mouse} <= 0.9 &&
        $MOUSE_HUMAN_ORTHOLOGY_SCORE_2{$human_mouse} && $MOUSE_HUMAN_ORTHOLOGY_SCORE_2{$human_mouse} <= 0.9
        ) {
        return 1;
    }
    return 0;
}

sub print_result {
    my ($human_gene, $mouse_gene) = @_;
    my $human_mouse = "${human_gene}\t${mouse_gene}";
    print join("\t",
               $human_gene,
               $mouse_gene,
               $HUMAN_MOUSE_BIT_SCORE{$human_mouse} || 0,
               $MOUSE_HUMAN_BIT_SCORE{$human_mouse} || 0,
               $HUMAN_MOUSE_ORTHOLOGY_SCORE{$human_mouse} || 0,
               $MOUSE_HUMAN_ORTHOLOGY_SCORE{$human_mouse} || 0,
               $MIN_ORTHOLOGY_SCORE{$human_mouse} || 0,
               $HUMAN_MOUSE_ORTHOLOGY_SCORE_2{$human_mouse} || 0,
               $MOUSE_HUMAN_ORTHOLOGY_SCORE_2{$human_mouse} || 0,
               min($HUMAN_MOUSE_ORTHOLOGY_SCORE_2{$human_mouse} || 0, $MOUSE_HUMAN_ORTHOLOGY_SCORE_2{$human_mouse} || 0)
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
