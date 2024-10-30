#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM assembly_summary_refseq.txt > assembly_summary_human_mouse.txt
-r: reference genome only
";

my %OPT;
getopts('r', \%OPT);

my $TAXID_COL = 0; # default column for taxid
my $reference_col;
my $human_ref = "";
my $human_others = "";
my $mouse = "";
while (<>) {
    chomp;
    if (/^#+  /) {
        next;
    }
    my @f = split(/\t/, $_, -1);
    if (/^#/) {
        print "$_\n";
        for (my $i=0; $i<@f; $i++) {
            if ($f[$i] eq "taxid") {
                $TAXID_COL = $i;
            }
            if ($f[$i] eq "refseq_category") {
                $reference_col = $i;
            }
        }
        next;
    }
    if ($OPT{r}) {
        if ($f[$reference_col] ne "reference genome") {
            next;
        }
    }
    if ($f[$TAXID_COL] eq "9606") {
        if ($reference_col and $f[$reference_col] eq "reference genome") {
            $human_ref .= "$_\n";
        } else {
            $human_others .= "$_\n";
        }
    }
    if ($f[$TAXID_COL] eq "10090") {
        $mouse .= "$_\n";
    }
}
print $human_ref;
print $human_others;
print $mouse;
