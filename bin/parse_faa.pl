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

!@ARGV && -t and die $USAGE;
my $ID = "";
my $SEQ = "";
while (<>) {
    chomp;
    if (/^>(\S+)/) {
        my $id = $1;
        print_previous_seq_length();
        $ID = $id;
        $SEQ = "";
    } else {
        $SEQ .= $_;
    }
}
print_previous_seq_length();

################################################################################
### Function ###################################################################
################################################################################

sub print_previous_seq_length {
    if ($SEQ) {
        my $len = length($SEQ);
        print "$ID\t$len\n";
    }
}
