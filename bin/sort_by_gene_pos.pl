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

my $READTHROUGH_GENE_LIST = "/home/chiba/github/bioal/human-mouse/readthrough";
my %READTHROUGH_GENE;
open(FILE, "$READTHROUGH_GENE_LIST") || die "$!";
while (<FILE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene_id = $f[1];
    $READTHROUGH_GENE{$gene_id} = 1;
}
close(FILE);

my %GENE;
while (<STDIN>) {
    chomp;
    if ($. == 1) {
        next;
    }
    my @f = split(/\t/, $_, -1);
    my $gene_id = $f[1];
    my $nm = $f[3];
    my $np = $f[5];
    my $nc = $f[7];
    my $start_pos = $f[9];
    my $end_pos = $f[10];
    my $orientation = $f[11];
    my $assembly = $f[12];
    if (! is_target_assembly($nc, $assembly)) {
        next;
    }
    if ($READTHROUGH_GENE{$gene_id}) {
        next;
    }
    if ($start_pos !~ /^\d+$/) {
        die;
    }
    if ($end_pos !~ /^\d+$/) {
        die;
    }
    if ($np eq "-") {
        next;
    }
    if (!$GENE{$nc}{$gene_id}{start_pos} || $start_pos < $GENE{$nc}{$gene_id}{start_pos}) {
        $GENE{$nc}{$gene_id}{start_pos} = $start_pos;
    }
    if (!$GENE{$nc}{$gene_id}{end_pos} || $end_pos > $GENE{$nc}{$gene_id}{end_pos}) {
        $GENE{$nc}{$gene_id}{end_pos} = $end_pos;
    }
    if ($GENE{$nc}{$gene_id}{orientation}) {
        if ($GENE{$nc}{$gene_id}{orientation} ne $orientation) {
            die "Inconsistent orientation for $gene_id on $nc: $GENE{$nc}{$gene_id}{orientation} vs $orientation";
        }
    } else {
        $GENE{$nc}{$gene_id}{orientation} = $orientation;
    }
}

for my $nc (sort keys %GENE) {
    my @genes = sort {
        my $start_a = $GENE{$nc}{$a}{start_pos};
        my $start_b = $GENE{$nc}{$b}{start_pos};
        my $end_a = $GENE{$nc}{$a}{end_pos};
        my $end_b = $GENE{$nc}{$b}{end_pos};
        if ($start_a != $start_b) {
            return $start_a <=> $start_b;
        }
        return $end_a <=> $end_b;
    } keys %{$GENE{$nc}};
    my %used_pos;
    for my $gene_id (@genes) {
        my $start_pos = $GENE{$nc}{$gene_id}{start_pos};
        my $end_pos = $GENE{$nc}{$gene_id}{end_pos};
        my $orientation = $GENE{$nc}{$gene_id}{orientation};
        print join("\t", $nc, $gene_id, $start_pos, $end_pos, $orientation), "\n";
    }
}

################################################################################
### Function ###################################################################
################################################################################
sub is_target_assembly {
    my ($nc, $assembly) = @_;

    if ($assembly eq "Reference GRCh38.p14 Primary Assembly") {
        return 1;
    }
    if ($assembly eq "Reference GRCm39 C57BL/6J") {
        return 1;
    }
    if ($nc eq "NC_012920.1") {
        # human mitochondrial DNA
        return 1;
    }
    if ($nc eq "NC_005089.1") {
        # mouse mitochondrial DNA
        return 1;
    }
}
