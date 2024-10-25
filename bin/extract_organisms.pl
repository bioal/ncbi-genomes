#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM TAXON...
-s: sort by ID
";

my %OPT;
getopts('s', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

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
                    last;
                }
            }
        }
        if ($TAXON{$f[$TAXID_COL]}) {
            if ($OPT{s}) {
                $GENOME{$id} = $_;
            } else {
                print "$_\n";
            }
        }
    }
    if ($OPT{s}) {
        for my $id (sort keys %GENOME) {
            print "$GENOME{$id}\n";
        }
    }
}
