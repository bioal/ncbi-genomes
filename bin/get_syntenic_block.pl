#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-b: number of genes before the gene
-a: number of genes after the gene
";

my %OPT;
getopts('b:a:', \%OPT);

my $NUM_BEFORE = 5;
if (defined($OPT{'b'})) {
    $NUM_BEFORE = $OPT{'b'};
}
my $NUM_AFTER = 5;
if (defined($OPT{'a'})) {
    $NUM_AFTER = $OPT{'a'};
}

my %SYMBOL;
my %SYMBOL2ID;
read_gene_info(
    "/home/chiba/github/bioal/human-mouse/ncbi_orthologs/gene_info.2026-04-02",
    \%SYMBOL);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my %GENE;
for my $gene (@ARGV) {
    if ($gene =~ /^\d+$/) {
        $GENE{$gene} = 1;
    } elsif ($SYMBOL2ID{$gene}) {
        for my $geneid (@{$SYMBOL2ID{$gene}}) {
            $GENE{$geneid} = 1;
        }
    } else {
        print STDERR "No such symbol: $gene\n";
    }
}

my @LINE = <STDIN>;
chomp(@LINE);

my @NC;
my %HIT;
for (my $i=0; $i<@LINE; $i++) {
    my @f = split(/\t/, $LINE[$i], -1);
    my $nc = $f[0];
    my $gene = $f[1];
    $NC[$i] = $nc;
    if ($GENE{$gene}) {
        $HIT{$i} = 1;
    }
}

for my $i (sort {$a <=> $b} keys %HIT) {
    my $start_idx = get_start_idx($i, $NUM_BEFORE);
    my $end_idx = get_end_idx($i, $NUM_AFTER);
    for (my $j=$start_idx; $j<=$end_idx; $j++) {
        my @f = split(/\t/, $LINE[$j], -1);
        my $nc = $f[0];
        my $gene = $f[1];
        my $start_pos = $f[2];
        my $end_pos = $f[3];
        my $orientation = $f[4];
        print join("\t",
                   $nc,
                   $gene,
                   format_pos($start_pos),
                   format_pos($end_pos),
                   $orientation,
                   get_symbol($gene),
            ), "\n";
    }
    print "\n";
}

################################################################################
### Function ###################################################################
################################################################################
sub get_symbol {
    my ($geneid) = @_;

    if ($SYMBOL{$geneid} && $GENE{$geneid}) {
        return "[$SYMBOL{$geneid}]";
    } elsif ($SYMBOL{$geneid}) {
        return $SYMBOL{$geneid};
    } else {
        return 0;
    }
}

sub get_start_idx {
    my ($i, $num) = @_;

    my $start_idx = $i;
    my $count = 0;
    while ($count < $num && $start_idx > 0) {
        $start_idx--;
        if ($NC[$start_idx] eq $NC[$i]) {
            $count++;
        }
    }

    return $start_idx;
}

sub get_end_idx {
    my ($i, $n) = @_;

    my $end_idx = $i;
    my $count = 0;
    while ($count < $n && $end_idx < $#LINE) {
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
