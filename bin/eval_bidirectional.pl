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

my %BIT_SCORE;
my %ORTHOLOGY_SCORE;
my %GROUPED_ORTHOLOGY_SCORE;
open(HUMAN_MOUSE, "$HUMAN_MOUSE") || die "$!";
while (<HUMAN_MOUSE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];
    my $bit_score = $f[11];
    my $orthology_score = $f[12];
    my $grouped_orthology_score = $f[13];
    $BIT_SCORE{"${human_gene}\t${mouse_gene}"} = $bit_score;
    $ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"} = $orthology_score;
    $GROUPED_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"} = $grouped_orthology_score;
}
close(HUMAN_MOUSE);

my %REVERSE_BIT_SCORE;
my %REVERSE_ORTHOLOGY_SCORE;
my %REVERSE_GROUPED_ORTHOLOGY_SCORE;
my %MIN_ORTHOLOGY_SCORE;
open(MOUSE_HUMAN, "$MOUSE_HUMAN") || die "$!";
while (<MOUSE_HUMAN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $mouse_gene = $f[0];
    my $human_gene = $f[1];
    my $mouse_human_bit_score = $f[11];
    my $mouse_human_orthology_score = $f[12];
    my $mouse_human_grouped_orthology_score = $f[13];
    $REVERSE_BIT_SCORE{"${human_gene}\t${mouse_gene}"} = $mouse_human_bit_score;
    $REVERSE_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"} = $mouse_human_orthology_score;
    $REVERSE_GROUPED_ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"} = $mouse_human_grouped_orthology_score;
    if ($ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"}) {
        my $human_mouse_orthology_score = $ORTHOLOGY_SCORE{"${human_gene}\t${mouse_gene}"};
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

    if ($REVERSE_BIT_SCORE{$human_mouse} &&
        $REVERSE_ORTHOLOGY_SCORE{$human_mouse} <= 1 &&
        $BIT_SCORE{$human_mouse} &&
        $ORTHOLOGY_SCORE{$human_mouse} <= 1 ) {
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

    if (! $BIT_SCORE{$human_mouse} &&
          $REVERSE_ORTHOLOGY_SCORE{$human_mouse} <= 1) {
        return 1;
    }

    if (! $REVERSE_BIT_SCORE{$human_mouse} &&
          $ORTHOLOGY_SCORE{$human_mouse} <= 1 ) {
        return 1;
    }

    if ($ORTHOLOGY_SCORE{$human_mouse}   && $ORTHOLOGY_SCORE{$human_mouse}   <= 1 &&
        $REVERSE_ORTHOLOGY_SCORE{$human_mouse}   && $REVERSE_ORTHOLOGY_SCORE{$human_mouse}   <= 1 &&
        $GROUPED_ORTHOLOGY_SCORE{$human_mouse} && $GROUPED_ORTHOLOGY_SCORE{$human_mouse} <= 0.9 &&
        $REVERSE_GROUPED_ORTHOLOGY_SCORE{$human_mouse} && $REVERSE_GROUPED_ORTHOLOGY_SCORE{$human_mouse} <= 0.9
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
               $BIT_SCORE{$human_mouse} || 0,
               $REVERSE_BIT_SCORE{$human_mouse} || 0,
               $ORTHOLOGY_SCORE{$human_mouse} || 0,
               $REVERSE_ORTHOLOGY_SCORE{$human_mouse} || 0,
               $MIN_ORTHOLOGY_SCORE{$human_mouse} || 0,
               $GROUPED_ORTHOLOGY_SCORE{$human_mouse} || 0,
               $REVERSE_GROUPED_ORTHOLOGY_SCORE{$human_mouse} || 0,
               min($GROUPED_ORTHOLOGY_SCORE{$human_mouse} || 0, $REVERSE_GROUPED_ORTHOLOGY_SCORE{$human_mouse} || 0)
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
