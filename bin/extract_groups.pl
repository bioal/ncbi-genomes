#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM assembly_summary_refseq.txt > group_count.txt
-a: output all groups
";

my %OPT;
getopts('a', \%OPT);

!@ARGV && -t and die $USAGE;

### Predefined groups
my @EUKARYOTES = (
    "vertebrate_mammalian",
    "vertebrate_other",
    "invertebrate",
    "plant",
    "fungi",
    "protozoa",
    );
my @PROKARYOTES = (
    "bacteria",
    "archaea",
    );
my @VIRUSES = (
    "viral",
    );

my %GROUP;
for my $group (@EUKARYOTES, @PROKARYOTES, @VIRUSES) {
    $GROUP{$group} = 1;
}

### Count genomes for each group
my %COUNT;
my %COUNT_OTHERS;
while (<>) {
    chomp;
    if (/^#/) {
        next;
    }

    my @f = split(/\t/, $_, -1);
    if (@f != 38) {
        die $_;
    }
    my $id = $f[0];
    my $group = $f[24];
    if ($GROUP{$group}) {
        $COUNT{$group} ++;
    } else {
        $COUNT_OTHERS{$group} ++;
    }
}

### Print counts for each group in the order of predefined groups
my $out_eukaryotes = "";
my $count_eukaryotes = 0;
for my $group (@EUKARYOTES) {
    my $count = $COUNT{$group} || 0;
    $count_eukaryotes += $count;
    $out_eukaryotes .= "$count\t$group\n";
}
if ($OPT{a} || $count_eukaryotes) {
    print $out_eukaryotes;
}

my $out_prokaryotes = "";
my $count_prokaryotes = 0;
for my $group (@PROKARYOTES) {
    my $count = $COUNT{$group} || 0;
    $count_prokaryotes += $count;
    $out_prokaryotes .= "$count\t$group\n";
}
if ($OPT{a} || $count_prokaryotes) {
    print $out_prokaryotes;
}

my $out_viruses = "";
my $count_viruses = 0;
for my $group (@VIRUSES) {
    my $count = $COUNT{$group} || 0;
    $count_viruses += $count;
    $out_viruses .= "$count\t$group\n";
}
if ($OPT{a} || $count_viruses) {
    print $out_viruses;
}

### Print other categories if any detected
my @OTHERS;
for my $group (sort { $COUNT_OTHERS{$b} <=> $COUNT_OTHERS{$a} } keys %COUNT_OTHERS) {
    print "$group\t$COUNT_OTHERS{$group}\n";
    push(@OTHERS, $group);
}
if (@OTHERS) {
    print STDERR "Others: @OTHERS\n";
}
