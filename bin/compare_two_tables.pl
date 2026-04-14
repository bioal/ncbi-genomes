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
my ($RESULT1, $RESULT2) = @ARGV;

my %RESULT1;
open(RESULT1, "$RESULT1") || die "$!";
while (<RESULT1>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    $RESULT1{"${gene1}\t${gene2}"} = $_;
}
close(RESULT1);

my %RESULT2;
open(RESULT2, "$RESULT2") || die "$!";
while (<RESULT2>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    $RESULT2{"${gene1}\t${gene2}"} = $_;
}
close(RESULT2);

foreach my $key (sort keys %RESULT1) {
    if (!exists $RESULT2{$key}) {
        print "< ", $RESULT1{$key}, "\n";
    }
}
print "==\n";
foreach my $key (sort keys %RESULT2) {
    if (!exists $RESULT1{$key}) {
        print "> ", $RESULT2{$key}, "\n";
    }
}

