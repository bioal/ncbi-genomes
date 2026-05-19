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

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($INPUT_GENE) = @ARGV;

my %INFO;
my %SYMBOL2ID;
read_gene_info(
    "/home/chiba/github/bioal/human-mouse/ncbi_orthologs/gene_info.2026-04-02",
    \%INFO);

if ($SYMBOL2ID{$INPUT_GENE}) {
    $INPUT_GENE = $SYMBOL2ID{$INPUT_GENE};
}

my $INPUT_TAXID = $INFO{$INPUT_GENE}{taxid};
my $OUTPUT_TAXID = $INPUT_TAXID eq "9606" ? "10090" : "9606";
my $OUTPUT_FILE = "9606-10090";

my $INPUT_ORGANISM = $INPUT_TAXID;
my $OUTPUT_ORGANISM = $OUTPUT_TAXID;
if (-f "human-mouse.ortholog") {
    if ($INPUT_TAXID eq "9606") {
        $INPUT_ORGANISM = "human";
        $OUTPUT_ORGANISM = "mouse";
    } elsif ($INPUT_TAXID eq "10090") {
        $INPUT_ORGANISM = "mouse";
        $OUTPUT_ORGANISM = "human";
    } else {
        die "Unknown taxid: $INPUT_TAXID";
    }
    $OUTPUT_FILE = "human-mouse";
}

my %SEED_GENES;
$SEED_GENES{$INPUT_GENE} = 1;
extract_orthologs("${INPUT_ORGANISM}.orthology", $INPUT_GENE, \%SEED_GENES);

print "${INPUT_ORGANISM}:$INPUT_GENE ", get_symbols($INPUT_GENE), "\n";

my %PARALOGOUS_GENES;
$PARALOGOUS_GENES{$INPUT_GENE} = 1;
extract_paralogs("${INPUT_ORGANISM}.paralogy", $INPUT_GENE, \%PARALOGOUS_GENES);

my %HOMOLOGOUS_GENES;
my %SIMILAR_GENES;
$SIMILAR_GENES{$INPUT_GENE} = 1;
extract_genes("${INPUT_ORGANISM}.orthology", $INPUT_GENE, \%HOMOLOGOUS_GENES);
extract_genes("${INPUT_ORGANISM}.paralogy", $INPUT_GENE, \%SIMILAR_GENES);

output_table("${INPUT_ORGANISM}.paralogy", \%PARALOGOUS_GENES);
output_table("${INPUT_ORGANISM}.orthology", \%PARALOGOUS_GENES);

output_table("${OUTPUT_ORGANISM}.orthology", \%HOMOLOGOUS_GENES);
output_table("${OUTPUT_ORGANISM}.paralogy", \%HOMOLOGOUS_GENES);

output_table("${OUTPUT_FILE}.ortholog", \%SIMILAR_GENES);

################################################################################
### Function ###################################################################
################################################################################
sub extract_paralogs {
    my ($file, $input_gene, $r_hits) = @_;

    open(FILE1, $file) || die "$!";
    while (<FILE1>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $gene1 = $f[0];
        my $gene2 = $f[1];
        my $paralogy = $f[3];
        if ($gene1 eq $input_gene) {
            if ($paralogy > 0.5) {
                ${$r_hits}{$gene2} = 1;
            }
        }
    }
    close(FILE1);
}

sub extract_orthologs {
    my ($file, $input_gene, $r_hits) = @_;

    open(FILE1, $file) || die "$!";
    while (<FILE1>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $gene1 = $f[0];
        my $gene2 = $f[1];
        my $orthology = $f[5];
        if ($gene1 eq $input_gene) {
            if ($orthology > 0.5) {
                ${$r_hits}{$gene2} = 1;
            }
        }
    }
    close(FILE1);
}

sub extract_genes {
    my ($file, $input_gene, $r_hits) = @_;

    open(FILE1, $file) || die "$!";
    while (<FILE1>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $gene1 = $f[0];
        my $gene2 = $f[1];
        if ($gene1 eq $input_gene) {
            ${$r_hits}{$gene2} = 1;
        }
    }
    close(FILE1);
}

sub output_table {
    my ($file, $r_target_genes, $r_seed_genes) = @_;

    my @target_genes = sort {$a<=>$b} keys %{$r_target_genes};
    my $target_genes = join(",", @target_genes);
    my $target_symbols = get_symbols($target_genes);

    my $seed_genes = join(",", keys %SEED_GENES);
    if ($r_seed_genes) {
        $seed_genes = join(",", keys %{$r_seed_genes});
    }
    print "\n";
    print "== $file for $target_genes ($target_symbols)\n";
    system "cat $file | grep_genes_in_table.pl -s $seed_genes $target_genes | align_column";
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
        $SYMBOL2ID{$symbol} = $geneid;
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
            if ($SEED_GENES{$gene}) {
                $symbol = "\e[91m$symbol\e[0m";
            } else {
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
