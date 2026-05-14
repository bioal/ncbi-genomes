#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-c: number of genes before and after the gene
-b: number of genes before the gene
-a: number of genes after the gene
";

my %OPT;
getopts('b:a:c:', \%OPT);

my $NUM_BEFORE = 5;
my $NUM_AFTER = 5;
if (defined($OPT{'c'})) {
    $NUM_BEFORE = $OPT{'c'};
    $NUM_AFTER = $OPT{'c'};
}
if (defined($OPT{'b'})) {
    $NUM_BEFORE = $OPT{'b'};
}
if (defined($OPT{'a'})) {
    $NUM_AFTER = $OPT{'a'};
}

my %SYMBOL;
my %SYMBOL2ID;
read_gene_info(
    "/home/chiba/github/bioal/human-mouse/ncbi_orthologs/gene_info.2026-04-02",
    \%SYMBOL);

my %ORTHOLOG;
read_orthology("/home/chiba/github/bioal/human-mouse/human-mouse.v1.tsv");

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my @GENE = split(/,/, join(",", @ARGV));

my %GENE;
my @INPUT_GENE;
for my $gene (@GENE) {
    if ($gene =~ /^\d+$/) {
        $GENE{$gene} = 1;
        push @INPUT_GENE, $gene;
    } elsif ($SYMBOL2ID{$gene}) {
        for my $geneid (@{$SYMBOL2ID{$gene}}) {
            $GENE{$geneid} = 1;
            push @INPUT_GENE, $geneid;
        }
    } else {
        print STDERR "No such symbol: $gene\n";
    }
}

my @LINE = <STDIN>;
chomp(@LINE);

my @NC;
my %FOUND;
my %REVERSE_ORIENTATION;
for (my $i=0; $i<@LINE; $i++) {
    my @f = split(/\t/, $LINE[$i], -1);
    my $nc = $f[0];
    my $gene = $f[1];
    my $orientation = $f[4];
    $NC[$i] = $nc;
    if ($GENE{$gene}) {
        $FOUND{$gene} = $i;
    }
    if ($orientation eq "-") {
        $REVERSE_ORIENTATION{$gene} = 1;
    }
}

my %FOUND_LINES;
my %REMEMBER_GENE;
my %SYMBOL_MAX_LEN;
for my $anchor (keys %FOUND) {
    my $i = $FOUND{$anchor};
    my $start_idx = get_start_idx($i);
    my $end_idx = get_end_idx($i);
    my @line;
    for (my $j=$start_idx; $j<=$end_idx; $j++) {
        my @f = split(/\t/, $LINE[$j], -1);
        my $gene = $f[1];
        $REMEMBER_GENE{$gene} = 1;
        remember_symbol_max_len($anchor, $gene);
        push @line, $LINE[$j];
    }
    $FOUND_LINES{$anchor} = \@line;
}

my %HIGHLIGHT_GENE;
for my $gene (keys %REMEMBER_GENE) {
    if ($ORTHOLOG{$gene}) {
        my $mouse_gene = $ORTHOLOG{$gene};
        if ($REMEMBER_GENE{$mouse_gene}) {
            $HIGHLIGHT_GENE{$gene} = 1;
            $HIGHLIGHT_GENE{$mouse_gene} = 1;
        }
    }
}

my %BLOCK;
for my $anchor (keys %FOUND_LINES) {
    my $block = "";
    for my $line (@{$FOUND_LINES{$anchor}}) {
        my @f = split(/\t/, $line, -1);
        my $nc = $f[0];
        my $gene = $f[1];
        my $start_pos = $f[2];
        my $end_pos = $f[3];
        my $orientation = $f[4];
        $block .= join("\t",
                     $nc,
                     $gene,
                     format_pos($start_pos),
                     format_pos($end_pos),
                     $orientation,
                     get_symbol($anchor, $gene),
            ) . "\n";
    }
    $BLOCK{$anchor} = $block;
}

my @OUT;
for my $gene (@INPUT_GENE) {
    if ($FOUND{$gene}) {
        my $out = $BLOCK{$gene};
        if ($REVERSE_ORIENTATION{$gene}) {
            $out = reverse_block($BLOCK{$gene});
        }
        push @OUT, $out;
    }
}

my $OUT = paste_blocks(@OUT);
print "$OUT\n";

################################################################################
### Function ###################################################################
################################################################################

sub read_orthology {
    my ($file, $r_hash) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        if (@f != 4) {
            die "Error: Invalid orthology file format\n";
        }
        if ($. == 1) {
            next; # Skip header
        }
        my $human_gene = $f[0];
        my $mouse_gene = $f[1];
        $ORTHOLOG{$human_gene} = $mouse_gene;
    }
    close(FILE);

    return 0;
}

sub remember_symbol_max_len {
    my ($anchor, $gene) = @_;

    my $symbol = $SYMBOL{$gene} || 0;
    if (! defined($SYMBOL_MAX_LEN{$anchor}) ||
        length($symbol) > $SYMBOL_MAX_LEN{$anchor}) {
        $SYMBOL_MAX_LEN{$anchor} = length($symbol);
    }
}

sub reverse_block {
    my ($block) = @_;

    my @lines = split(/\n/, $block);
    @lines = reverse @lines;

    return join("\n", @lines);
}

sub paste_blocks {
    my (@block) = @_;

    my @out;
    for my $block (@block) {
        my @block_line = split(/\n/, $block);
        for (my $i=0; $i<@block_line; $i++) {
            if ($out[$i]) {
                $out[$i] .= "\t" . $block_line[$i];
            } else {
                $out[$i] = $block_line[$i];
            }
        }
    }

    return join("\n", @out);
}

sub get_symbol {
    my ($anchor, $geneid) = @_;

    if ($SYMBOL{$geneid}) {
        my $symbol = $SYMBOL{$geneid};
        my $padding_len = $SYMBOL_MAX_LEN{$anchor} - length($symbol);
        my $padding = " " x $padding_len;
        if ($GENE{$geneid}) {
            return "[[ " . $symbol . $padding . "]]";
        } elsif ($HIGHLIGHT_GENE{$geneid}) {
            return " [ " . $symbol . $padding . "]";
        } else {
            return "   " . $symbol;
        }
    }

    return 0;
}

sub get_start_idx {
    my ($i) = @_;

    my $start_idx = $i;
    my $count = 0;
    while ($count < $NUM_BEFORE && $start_idx > 0) {
        $start_idx--;
        if ($NC[$start_idx] eq $NC[$i]) {
            $count++;
        }
    }

    return $start_idx;
}

sub get_end_idx {
    my ($i) = @_;

    my $end_idx = $i;
    my $count = 0;
    while ($count < $NUM_AFTER && $end_idx < $#LINE) {
        $end_idx++;
        if ($NC[$end_idx] eq $NC[$i]) {
            $count++;
        }
    }

    return $end_idx;
}

sub format_pos {
    my ($n) = @_;

    my $out = '';
    while ($n > 0) {
        my $r = $n % 1000;
        $n = int($n / 1000);
        if ($n > 0) {
            $r = sprintf(",%03d", $r);
        }
        $out = $r . $out;
    }

    return $out;
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
        if ($SYMBOL2ID{$symbol}) {
            push @{$SYMBOL2ID{$symbol}}, $geneid;
        } else {
            $SYMBOL2ID{$symbol} = [$geneid];
        }
    }
    close(FILE);

    return 0;
}
