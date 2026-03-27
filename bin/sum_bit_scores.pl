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
my ($FORWARD, $REVERSE) = @ARGV;

my %HASH;
my %FORWARD_BIT_SCORE;
open(FORWARD, "$FORWARD") || die "$!";
while (<FORWARD>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $bit_score = $f[11];
    $FORWARD_BIT_SCORE{"$gene1\t$gene2"} = $bit_score;
    $HASH{"$gene1\t$gene2"} = $bit_score;
}
close(FORWARD);

my %REVERSE_BIT_SCORE;
open(REVERSE, "$REVERSE") || die "$!";
while (<REVERSE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene2 = $f[0];
    my $gene1 = $f[1];
    my $bit_score = $f[11];
    $REVERSE_BIT_SCORE{"$gene1\t$gene2"} = $bit_score;
    if ($HASH{"$gene1\t$gene2"}) {
        $HASH{"$gene1\t$gene2"} += $bit_score;
    } else {
        $HASH{"$gene1\t$gene2"} = $bit_score;
    }
}
close(REVERSE);

# sort by sum of bit scores
foreach my $pair (sort { $HASH{$b} <=> $HASH{$a} } keys %HASH) {
    print join("\t", $pair,
               $FORWARD_BIT_SCORE{$pair} || 0,
               $REVERSE_BIT_SCORE{$pair} || 0,
               $HASH{$pair});
    print "\n";
}
