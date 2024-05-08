#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM [assembly_summary.txt]
-r: reference or representative genomes only
";

my %OPT;
getopts('r', \%OPT);

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

my %GENOME;
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

    if ($OPT{r}) {
        if ($f[4] eq "na") {
            next;
        }
    }

    if ($EUKARYOTES{$group}) {
        $GENOME{$id} = $_;
    } elsif ($OTHERS{$group}) {
    } else {
        die $_;
    }
}

for my $id (sort keys %GENOME) {
    print "$GENOME{$id}\n";
}
