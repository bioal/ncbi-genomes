#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM query target
-f: fast-mode
-t: output title
";

my %OPT;
getopts('tf', \%OPT);

my $outfmt = "";
if ($OPT{t}) {
    $outfmt .= "qtitle stitle";
}

if (@ARGV != 2) {
    print STDERR $USAGE;
    exit 1;
}
my ($query, $target) = @ARGV;

my $out_file = "$query-$target.tsv";
my $err_file = "$query-$target.err";

my $options = "";
if ($OPT{f}) {
} else {
    $options .= "--very-sensitive";
}

system "diamond blastp $options -k 1000 -q $query -d $target --outfmt 6 qseqid sseqid bitscore $outfmt -o $out_file 2> $err_file";

system "cat $out_file";
