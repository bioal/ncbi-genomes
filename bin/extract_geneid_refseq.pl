#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: cat gene2refseq.gz | gz | $PROGRAM [-f target_taxid] [9606 10090]
-f TARGET_TAXID_FILE
-o OUT_DIR
-v: refseq with version
";

my %OPT;
getopts('f:o:v', \%OPT);

if ($OPT{o}) {
    mkdir_with_check($OPT{o});
}

my %TARGET_TAX;
if ($OPT{f}) {
    if (!-f $OPT{f}) {
        print STDERR "File not found: $OPT{f}\n";
        exit 1;
    }
    open my $fh, '<', $OPT{f} or die "Cannot open file $OPT{f}: $!";
    while (<$fh>) {
        chomp;
        if (/^\d+$/) {
            $TARGET_TAX{$_} = 1;
        } else {
            print STDERR "Invalid taxid in file: $_\n";
            exit 1;
        }
    }
    close $fh;
}
for my $taxid (@ARGV) {
    if ($taxid =~ /^\d+$/) {
        $TARGET_TAX{$taxid} = 1;
    } else {
        print STDERR "Invalid taxid: $taxid\n";
        exit 1;
    }
}

my %hash;
while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    if (@f != 16) {
        die;
    }
    if (/^#/) {
        next;  # Skip header lines
    }
    my $taxid = $f[0];
    my $geneid = $f[1];
    my $refseq = $f[5];
    if (%TARGET_TAX && !$TARGET_TAX{$taxid}) {
        next;
    }
    if ($refseq eq '-') {
        next;  # Skip if no RefSeq accession
    }
    if (!$OPT{v} && $refseq =~ /^(\S+)\.(\d+)$/) {
        $refseq = $1;
    }
    if ($hash{$taxid}{"$geneid\t$refseq"}) {
        next;  # Skip duplicates
    }
    $hash{$taxid}{"$geneid\t$refseq"} = 1;
    if (!$OPT{o}) {
        print "$geneid\t$refseq\n";
    }
}

if ($OPT{o}) {
    for my $taxid (sort {$a <=> $b} keys %hash) {
        my $out_file = "$OPT{o}/$taxid";
        open my $out_fh, '>', $out_file or die "Cannot open file $out_file: $!";
        for my $geneid_refseq (sort keys %{$hash{$taxid}}) {
            print $out_fh "$geneid_refseq\n";
        }
        close $out_fh;
    }
}

################################################################################
### Function ###################################################################
################################################################################

sub mkdir_with_check {
    my ($file_or_dir) = @_;

    system "mkdir -p $file_or_dir";
}
