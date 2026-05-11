#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

my %OPT;
getopts('', \%OPT);

if (@ARGV != 2) {
    print STDERR $USAGE;
    exit 1;
}
my ($HUMAN_MOUSE, $MOUSE_HUMAN) = @ARGV;

# Read orthology calculation files
my %BIT_SCORE;
my %ORTHOLOGY;
my %GROUPED_ORTHOLOGY;
my %PARALOGS;
read_directional_scores($HUMAN_MOUSE);
read_directional_scores($MOUSE_HUMAN);

my %PRINTED_GENE;

# Create anchor pairs between human and mouse genes
# not only the top score gene, but also other genes are included
# (score > 0.9 * top_score)
my $RATIO = 1;
# my $RATIO = 0.9;
my %TOP_SCORE;
my @ANCHOR_PAIR;
my %ANCHOR;
my @LINES = <STDIN>;
chomp(@LINES);
for my $line (@LINES) {
    my @f = split(/\t/, $line, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];
    my $bit_score = $f[-1];
    my $human_mouse = "${human_gene}\t${mouse_gene}";
    my $mouse_human = "${mouse_gene}\t${human_gene}";
    if ($ORTHOLOGY{$human_mouse} && $ORTHOLOGY{$human_mouse} > 1 ||
        $ORTHOLOGY{$mouse_human} && $ORTHOLOGY{$mouse_human} > 1) {
        if (! $ANCHOR{$human_gene} && ! $ANCHOR{$mouse_gene}) {
            push @ANCHOR_PAIR, "${human_gene}\t${mouse_gene}";
            $ANCHOR{$human_gene}{member} = $human_gene;
            $ANCHOR{$mouse_gene}{member} = $mouse_gene;
            $ANCHOR{$human_gene}{pair} = $mouse_gene;
            $ANCHOR{$mouse_gene}{pair} = $human_gene;
            $TOP_SCORE{$human_gene} = $bit_score;
            $TOP_SCORE{$mouse_gene} = $bit_score;
            remember_printed_genes($human_gene);
            remember_printed_genes($mouse_gene);
        } else {
            if ($TOP_SCORE{$human_gene} && $bit_score > $TOP_SCORE{$human_gene} * $RATIO) {
                my $mouse_anchor = $ANCHOR{$human_gene}{pair};
                if (! $PRINTED_GENE{$mouse_gene}) {
                    $ANCHOR{$mouse_anchor}{member} .= ",$mouse_gene";
                    remember_printed_genes($mouse_gene);
                }
            }
            if ($TOP_SCORE{$mouse_gene} && $bit_score > $TOP_SCORE{$mouse_gene} * $RATIO) {
                my $human_anchor = $ANCHOR{$mouse_gene}{pair};
                if (! $PRINTED_GENE{$human_gene}) {
                    $ANCHOR{$human_anchor}{member} .= ",$human_gene";
                    remember_printed_genes($human_gene);
                }
            }
        }
    }
}

for my $anchor_pair (@ANCHOR_PAIR) {
    my ($human_gene, $mouse_gene) = split(/\t/, $anchor_pair);
    my $human_output = $ANCHOR{$human_gene}{member};
    my $mouse_output = $ANCHOR{$mouse_gene}{member};

    # Add paralogs
    my $human_mouse = "${human_gene}\t${mouse_gene}";
    my $mouse_human = "${mouse_gene}\t${human_gene}";
    if ($PARALOGS{$human_mouse}) {
        my @paralogs = filter_paralogs($PARALOGS{$human_mouse}, $mouse_gene);
        if (@paralogs) {
            $human_output .= "," . join(",", @paralogs);
        }
    }
    if ($PARALOGS{$mouse_human}) {
        my @paralogs = filter_paralogs($PARALOGS{$mouse_human}, $human_gene);
        if (@paralogs) {
            $mouse_output .= "," . join(",", @paralogs);
        }
    }

    output_line($human_output, $mouse_output, $human_mouse, $mouse_human);
}

# Add many-to-many orthologs
for my $line (@LINES) {
    my @f = split(/\t/, $line, -1);
    my $human_gene = $f[0];
    my $mouse_gene = $f[1];

    if ($PRINTED_GENE{$human_gene} || $PRINTED_GENE{$mouse_gene}) {
        next;
    }

    my $human_mouse = "${human_gene}\t${mouse_gene}";
    my $mouse_human = "${mouse_gene}\t${human_gene}";
    if ($GROUPED_ORTHOLOGY{$human_mouse} && $GROUPED_ORTHOLOGY{$human_mouse} > 1 &&
        $GROUPED_ORTHOLOGY{$mouse_human} && $GROUPED_ORTHOLOGY{$mouse_human} > 1) {
        my $human_output = $human_gene;
        my $mouse_output = $mouse_gene;

        if ($PARALOGS{$human_mouse}) {
            my @paralogs = filter_printed_genes($PARALOGS{$human_mouse});
            if (@paralogs) {
                $human_output .= "," . join(",", @paralogs);
            }
        }
        if ($PARALOGS{$mouse_human}) {
            my @paralogs = filter_printed_genes($PARALOGS{$mouse_human});
            if (@paralogs) {
                $mouse_output .= "," . join(",", @paralogs);
            }
        }

        output_line($human_output, $mouse_output, $human_mouse, $mouse_human);
    }
}

################################################################################
### Function ###################################################################
################################################################################
sub read_directional_scores {
    my ($file) = @_;

    open(FILE, $file) or die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);

        my $gene1 = $f[0];
        my $gene2 = $f[1];
        my $bit_score = $f[-4];
        my $orthology = $f[-3];
        my $grouped_orthology = $f[-2];
        my $paralogs = $f[-1];

        my $pair = "${gene1}\t${gene2}";
        $BIT_SCORE{$pair} = $bit_score;
        $ORTHOLOGY{$pair} = $orthology;
        $GROUPED_ORTHOLOGY{$pair} = $grouped_orthology;
        $PARALOGS{$pair} = $paralogs;
    }
    close(FILE);
}

sub output_line {
    my ($human_output, $mouse_output, $human_mouse, $mouse_human) = @_;

    print join("\t",
               $human_output,
               $mouse_output,
               $BIT_SCORE{$human_mouse} || 0,
               $BIT_SCORE{$mouse_human} || 0,
               $ORTHOLOGY{$human_mouse} || 0,
               $ORTHOLOGY{$mouse_human} || 0,
               min($ORTHOLOGY{$human_mouse} || 0, $ORTHOLOGY{$mouse_human} || 0),
               $GROUPED_ORTHOLOGY{$human_mouse} || 0,
               $GROUPED_ORTHOLOGY{$mouse_human} || 0,
               min($GROUPED_ORTHOLOGY{$human_mouse} || 0, $GROUPED_ORTHOLOGY{$mouse_human} || 0)
        ), "\n";
    remember_printed_genes($human_output);
    remember_printed_genes($mouse_output);
}

sub remember_printed_genes {
    my ($genes) = @_;

    my @genes = split(/,/, $genes);
    foreach my $gene (@genes) {
        $PRINTED_GENE{$gene} = 1;
    }
}

sub filter_paralogs {
    my ($genes, $anchor) = @_;

    my @out;
    for my $gene (split(/,/, $genes)) {
        if ($ORTHOLOGY{"${anchor}\t${gene}"} &&
            $ORTHOLOGY{"${anchor}\t${gene}"} > 1) {
            if (! $PRINTED_GENE{$gene}) {
                push(@out, $gene);
            }
        }
    }

    return @out;
}

sub filter_printed_genes {
    my ($genes) = @_;

    my @out;
    for my $gene (split(/,/, $genes)) {
        if (! $PRINTED_GENE{$gene}) {
            push(@out, $gene);
        }
    }

    return @out;
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
