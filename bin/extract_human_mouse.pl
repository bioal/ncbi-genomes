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

my $human_ref = "";
my $human_others = "";
my $mouse = "";
while (<>) {
    chomp;
    if (/^#+  /) {
        next;
    }
    if (/^#/) {
        print "$_\n";
    }
    my @f = split(/\t/, $_, -1);
    if ($OPT{r}) {
        if ($f[4] ne "reference genome") {
            next;
        }
    }
    if ($f[5] eq "9606") {
        if ($f[4] eq "reference genome") {
            $human_ref .= "$_\n";
        } else {
            $human_others .= "$_\n";
        }
    }
    if ($f[5] eq "10090") {
        $mouse .= "$_\n";
    }
}
print $human_ref;
print $human_others;
print $mouse;
