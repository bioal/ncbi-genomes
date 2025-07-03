#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM query target
-f: fast-mode
-u: ultra-sensitive mode
-t: output title
-s: output to stdout
";

my %OPT;
getopts('futs', \%OPT);

if (@ARGV != 2) {
    print STDERR $USAGE;
    exit 1;
}
my ($query, $target) = @ARGV;

my $out_file = "$query-$target.tsv";
my $log_file = "$query-$target.log";

my $options = "";
if ($OPT{f}) {
} elsif ($OPT{u}) {
    $options .= "--ultra-sensitive";
} else {
    $options .= "--very-sensitive";
}

if ($OPT{t}) {
    my $outfmt = "";
    $outfmt .= "qtitle stitle";
    system "diamond blastp $options -k 1000 -q $query -d $target --outfmt 6 qseqid sseqid bitscore $outfmt -o $out_file 2> $log_file";
} else {
    system "diamond blastp $options -k 1000 -q $query -d $target -o $out_file 2> $log_file";
}

if ($OPT{s}) {
    system "cat $out_file";
}
