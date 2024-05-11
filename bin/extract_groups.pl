#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM assembly_summary_refseq.txt > group_count.txt
";

my %OPT;
getopts('', \%OPT);

!@ARGV && -t and die $USAGE;

### Predefined groups
my @GROUPS = (
    "vertebrate_mammalian",
    "vertebrate_other",
    "invertebrate",
    "plant",
    "fungi",
    "protozoa",
    "bacteria",
    "archaea",
    "viral",
    );    

my %GROUP;
for my $group (@GROUPS) {
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

### Print counts for each group in the order of @GROUPS
for my $group (@GROUPS) {
    my $count = $COUNT{$group} || 0;
    print "$count\t$group\n";
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
