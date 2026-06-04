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

my %TYPE;
while (<>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    if (@f != 3) {
        print STDERR "Error: $_\n";
        die;
    }
    my $genes1 = $f[0];
    my $gene2 = $f[1];
    my $type = $f[2];
    $TYPE{$genes1}{$gene2} = $type;
}

for my $genes1 (sort keys %TYPE) {
    my @gene2 = keys %{$TYPE{$genes1}};
    if (@gene2 == 1) {
        my $gene2 = $gene2[0];
        print join("\t", $genes1, $gene2, $TYPE{$genes1}{$gene2}), "\n";
        next;
    }

    @gene2 = sort { $TYPE{$genes1}{$a} cmp $TYPE{$genes1}{$b} } @gene2;
    my @type = uniq_type($genes1, @gene2);

    if (@type == 1) {
        my $type = $type[0];
        print join("\t", $genes1, join(",", @gene2), $type), "\n";
        next;
    }

    print join("\t", $genes1, join(",", @gene2), join(",", @type)), "\n";
}

################################################################################
### Function ###################################################################
################################################################################

sub uniq_type {
    my ($genes1, @gene2) = @_;

    my %hash;
    for my $gene2 (@gene2) {
        my $type = $TYPE{$genes1}{$gene2};
        $hash{$type} = 1;
    }
    my @type = sort { $a cmp $b } keys %hash;

    return @type;
}
