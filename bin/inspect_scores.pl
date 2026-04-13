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
my %INPUT_GENES;
$INPUT_GENES{$INPUT_GENE} = 1;

my %INFO;
read_gene_info(
    "/home/chiba/github/hchiba1/human-mouse/ncbi_orthologs/gene_info.2026-04-02",
    \%INFO);

my $INPUT_TAXID = $INFO{$INPUT_GENE}{taxid};
my $OUTPUT_TAXID = $INPUT_TAXID eq "9606" ? "10090" : "9606";
print "${INPUT_TAXID}:$INPUT_GENE ", get_symbols($INPUT_GENE), "\n";

my %PARALOGOUS_GENES;
my %ORTHOLOGOUS_GENES;
extract_genes("${INPUT_TAXID}.paralogy", $INPUT_GENE, \%PARALOGOUS_GENES);
extract_genes("${INPUT_TAXID}.orthology", $INPUT_GENE, \%ORTHOLOGOUS_GENES);

my %TARGET_GENES;
for my $gene(keys %INPUT_GENES) {
    $TARGET_GENES{$gene} = 1;
}
for my $gene(keys %PARALOGOUS_GENES) {
    $TARGET_GENES{$gene} = 1;
}

output_table("${INPUT_TAXID}.paralogy", \%TARGET_GENES);
output_table("${INPUT_TAXID}.orthology", \%TARGET_GENES);

output_table("${OUTPUT_TAXID}.paralogy", \%ORTHOLOGOUS_GENES);
output_table("${OUTPUT_TAXID}.orthology", \%ORTHOLOGOUS_GENES);

output_table("9606-10090.ortholog", \%TARGET_GENES);

################################################################################
### Function ###################################################################
################################################################################
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
    my ($file, $r_target_genes) = @_;

    my @target_genes = sort {$a<=>$b} keys %{$r_target_genes};
    my $target_genes = join(",", @target_genes);
    my $target_symbols = get_symbols($target_genes);
    print "\n";
    print "== $file for $target_genes ($target_symbols)\n";
    system "cat $file | extract_genes_from_table.pl $target_genes | align_column";
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
            push(@symbols, $INFO{$gene}{symbol});
        }
    }

    if (@symbols == 0) {
        return 0;
    } else {
        return join(",", @symbols);
    }
}
