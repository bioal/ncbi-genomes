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

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($FILE) = @ARGV;

my %HASH;
open(FILE, "$FILE") || die "$!";
while (<FILE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $bit_score = $f[11];
    if ($HASH{"$gene1\t$gene2"}) {
        die;
    } elsif ($HASH{"$gene2\t$gene1"}) {
        # $HASH{"$gene2\t$gene1"} += $bit_score;
        # $HASH{"$gene2\t$gene1"} /= 2;
        if ($HASH{"$gene2\t$gene1"} < $bit_score) {
            $HASH{"$gene2\t$gene1"} = $bit_score;
        }
    } else {
        $HASH{"$gene1\t$gene2"} = $bit_score;
    }
}
close(FILE);

# select max score for forward and reverse

foreach my $pair (sort { $HASH{$b} <=> $HASH{$a} } keys %HASH) {
    my @f = split(/\t/, $pair);
    if (@f != 2) {
        die;
    }
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    print join("\t", $gene1, $gene2, $HASH{$pair}), "\n";
    print join("\t", $gene2, $gene1, $HASH{$pair}), "\n";
}
