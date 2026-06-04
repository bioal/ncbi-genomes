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
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $type = $f[2];
    $TYPE{$gene1}{$gene2} = $type;
}

for my $gene1 (sort keys %TYPE) {
    my @gene2 = sort { $TYPE{$gene1}{$a} cmp $TYPE{$gene1}{$b} } keys %{$TYPE{$gene1}};
    if (@gene2 == 1) {
        my $type = $TYPE{$gene1}{$gene2[0]};
        print join("\t",
                   $gene1,
                   $gene2[0],
                   $type
            ), "\n";
    } else {
        my @type = check_types($gene1, @gene2);
        if (@type == 1) {
            my $type = $type[0];
            print join("\t",
                       $gene1,
                       join(",", @gene2),
                       $type
                ), "\n";
        } else {
            my $types = join(",", @type);
            my $genes2 = join(",", @gene2);
            print join("\t",
                       $gene1,
                       $genes2,
                       $types
                ), "\n";

            # if ($types eq "one,several") {
            # } else {
            #     print "== $types\n";
            #     for my $gene2 (@gene2) {
            #         print join("\t",
            #                    $gene1,
            #                    $gene2,
            #                    $TYPE{$gene1}{$gene2},
            #             ), "\n";
            #     }
            # }

        }
    }
}

sub check_types {
    my ($gene1, @gene2) = @_;

    # my $type = $TYPE{$gene1}{$gene2[0]};
    # for (my $i=1; $i<@gene2; $i++) {
    #     if ($TYPE{$gene1}{$gene2[$i]} ne $type) {
    #         return 0;
    #     }
    # }
    # return $type;

    my %hash;
    for my $gene2 (@gene2) {
        my $type = $TYPE{$gene1}{$gene2};
        $hash{$type} = 1;
    }
    my @type = sort { $a cmp $b } keys %hash;

    return @type;
}
