#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM TAXON...
-e: only eukaryotes
-r: only reference genomes
-s: sort by ID
";

my %OPT;
getopts('ers', \%OPT);

my %EUKARYOTES = (
    "vertebrate_mammalian" => 1,
    "vertebrate_other" => 1,
    "invertebrate" => 1,
    "plant" => 1,
    "fungi" => 1,
    "protozoa" => 1,
    );

my %OTHERS = (
    "bacteria" => 1,
    "archaea" => 1,
    "viral" => 1,
    );

my %TAXON;
for my $arg (@ARGV) {
    if ($arg eq "human") {
        $TAXON{"9606"} = 1;
    } elsif ($arg eq "mouse") {
        $TAXON{"10090"} = 1;
    } else {
        $TAXON{$arg} = 1;
    }
}

if (-t) {
    open(my $fh, "/home/chiba/github/bioal/ncbi-genomes/data/assembly_summary_refseq.txt") || die "$!";
    extract_data($fh);
    close($fh);
} else {
    extract_data(*STDIN);
}

################################################################################
### Function ###################################################################
################################################################################

sub extract_data {
    my ($fh) = @_;

    my %GENOME;
    my $TAXID_COL = 0; # default column for taxid
    my $group_col;
    my $reference_col;
    while (<$fh>) {
        chomp;
        if (/^#+  /) {
            next;
        }
        my @f = split(/\t/, $_, -1);
        my $id = $f[0];
        if (/^#/) {
            print "$_\n";
            for (my $i=0; $i<@f; $i++) {
                if ($f[$i] eq "taxid") {
                    $TAXID_COL = $i;
                }
                if ($f[$i] eq "group") {
                    $group_col = $i;
                }
                if ($f[$i] eq "refseq_category") {
                    $reference_col = $i;
                }
            }
            next;
        }
        if ($OPT{e} && $group_col) {
            my $group = $f[$group_col];
            if ($EUKARYOTES{$group}) {
            } elsif ($OTHERS{$group}) {
                next;
            } else {
                die $_;
            }
        }
        if ($OPT{r} && $reference_col) {
            my $val = $f[$reference_col];
            if ($val eq "na") {
                next;
            }
        }
        if (%TAXON && !$TAXON{$f[$TAXID_COL]}) {
            next;
        }
        if ($OPT{s}) {
            $GENOME{$id} = $_;
        } else {
            print "$_\n";
        }
    }
    if ($OPT{s}) {
        for my $id (sort keys %GENOME) {
            print "$GENOME{$id}\n";
        }
    }
}
