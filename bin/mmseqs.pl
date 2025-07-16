#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM query target
-s: 7.5 or 8.5 (default: 5.7)
";

my %OPT;
getopts('s:', \%OPT);

if (@ARGV != 2) {
    print STDERR $USAGE;
    exit 1;
}
my ($file1, $file2) = @ARGV;
my $name1 = basename $file1;
my $name2 = basename $file2;

my $out_file = "$name1-$name2.tsv";
my $log_file = "$name1-$name2.log";
my $tmp_dir = "$name1-$name2.tmp";

my $binary = "mmseqs-17-avx2";

my $options = "";
if ($OPT{s}) {
    $options .= "-s $OPT{s}";
}
# $options .= " --alignment-mode 4";

system "$binary easy-search $file1 $file2 $out_file $tmp_dir $options > $log_file";
