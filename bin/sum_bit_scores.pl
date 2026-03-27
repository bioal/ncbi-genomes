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
open(FORWARD, "$FORWARD") || die "$!";
while (<FORWARD>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $bit_score = $f[11];
    $HASH{"$gene1\t$gene2"} = $bit_score;
}
close(FORWARD);

open(REVERSE, "$REVERSE") || die "$!";
while (<REVERSE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene2 = $f[0];
    my $gene1 = $f[1];
    my $bit_score = $f[11];
    if ($HASH{"$gene1\t$gene2"}) {
        $HASH{"$gene1\t$gene2"} += $bit_score;
    } else {
        $HASH{"$gene1\t$gene2"} = $bit_score;
    }
}
close(REVERSE);

# sort by sum of bit scores
foreach my $pair (sort { $HASH{$b} <=> $HASH{$a} } keys %HASH) {
    print "$pair\t$HASH{$pair}\n";
}
