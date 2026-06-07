#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-d DIR    input directory (default: summary)
";

my %OPT;
getopts('d:', \%OPT);

my $INPUT_DIR = "summary";
if ($OPT{d}) {
    $INPUT_DIR = $OPT{d};
}

my $GENE_INFO = "/home/chiba/github/bioal/human-mouse/ncbi_orthologs/gene_info.2026-04-02";
my %SYMBOL_TO_ID;
my %SYNONYM_TO_ID;
my %INFO;
read_gene_info($GENE_INFO, \%SYMBOL_TO_ID, \%SYNONYM_TO_ID);

my @FILES;
if (@ARGV) {
    @FILES = @ARGV;
} else {
    @FILES = glob("$INPUT_DIR/*");
}
for my $file_path (@FILES) {
    extract_human_ortholog($file_path);
}

################################################################################
### Function ###################################################################
################################################################################
sub extract_human_ortholog {
    my ($file_path) = @_;

    my $filename;
    if ($file_path =~ /\/(\d+)$/) {
        $filename = $1;
    } elsif ($file_path =~ /\/(\d+)\.en/) {
        $filename = $1;
    } else {
        return;
    }

    open(FILE, "$file_path") || die "$!";
    while (<FILE>) {
        chomp;
        if (/Orthologous to human (\S+) \(.*?\); (\S+) \(.*?\); and (\S+)/) {
            my $symbol1 = $1;
            my $symbol2 = $2;
            my $symbol3 = $3;
            my $id1 = symbol_to_id($symbol1, $filename);
            my $id2 = symbol_to_id($symbol2, $filename);
            my $id3 = symbol_to_id($symbol3, $filename);
            if ($id1 && $id2 && $id3) {
                print "$id1,$id2,$id3\t$filename\tthree\n";
            }
        } elsif (/Orthologous to human (\S+) \(.*?\) and (\S+)/) {
            my $symbol1 = $1;
            my $symbol2 = $2;
            my $id1 = symbol_to_id($symbol1, $filename);
            my $id2 = symbol_to_id($symbol2, $filename);
            if ($id1 && $id2) {
                print "$id1,$id2\t$filename\ttwo\n";
            } elsif ($id1) {
                # Raph1: second symbol is errornous => omit it
                print "$id1\t$filename\tone\n";
            }
        } elsif (/Orthologous to human (\S+)/) {
            my $symbol = $1;
            my $id = symbol_to_id($symbol, $filename);
            if ($id) {
                print "$id\t$filename\tone\n";
            }
        } elsif (/Orthologous to several human genes including (\S+) \(.*?\) and (\S+)/) {
            my $symbol1 = $1;
            my $symbol2 = $2;
            my $id1 = symbol_to_id($symbol1, $filename);
            my $id2 = symbol_to_id($symbol2, $filename);
            if ($id1 && $id2) {
                print "$id1,$id2\t$filename\tseveral\n";
            }
        } elsif (/Orthologous to several human genes including (\S+) \(.*?\); (\S+) \(.*?\); and (\S+)/) {
            my $symbol1 = $1;
            my $symbol2 = $2;
            my $symbol3 = $3;
            my $id1 = symbol_to_id($symbol1, $filename);
            my $id2 = symbol_to_id($symbol2, $filename);
            my $id3 = symbol_to_id($symbol3, $filename);
            if ($id1 && $id2 && $id3) {
                print "$id1,$id2,$id3\t$filename\tseveral\n";
            }
        } elsif (/Orthologous to several human genes including (\S+)/) {
            my $symbol = $1;
            my $id = symbol_to_id($symbol, $filename);
            if ($id) {
                print "$id\t$filename\tseveral\n";
            }
        }
    }
    close(FILE);
}

sub symbol_to_id {
    my ($symbol, $filename) = @_;

    if ($SYMBOL_TO_ID{$symbol}) {
        my $id = $SYMBOL_TO_ID{$symbol};
        return $id;
    } elsif ($SYNONYM_TO_ID{$symbol}) {
        my @id = @{$SYNONYM_TO_ID{$symbol}};
        if (@id == 1) {
            return $id[0];
        } else {
            if ($symbol eq "CIR1") {
                return "9541";
            } elsif ($symbol eq "C17orf49") {
                return "124944";
            } elsif ($symbol eq "C18orf21") {
                # mapped to RMP24 and RMP24P1 (pseudo gene) => select RMP24
                return "83608";
            } elsif ($symbol eq "NDUFA4") {
                return "4697";
            } elsif ($symbol eq "TDGF1") {
                return "6997";
            } elsif ($symbol eq "DUSP13") {
                return "51207";
            } else {
                print STDERR "WARNING: $symbol is duplicated synonym ($filename)\n";
                return;
            }
        }
    } else {
        print STDERR "WARNING: $symbol is not found in gene_info ($filename)\n";
    }

    return;
}

sub read_gene_info {
    my ($file, $r_symbol, $r_synonym) = @_;

    open(FILE, "$file") || die "$!";
    while (<FILE>) {
        chomp;
        my @f = split(/\t/, $_, -1);
        my $taxid = $f[0];
        my $geneid = $f[1];
        my $synonyms = $f[4];
        my $type = $f[9];
        my $symbol = $f[10];
        $INFO{$geneid} = $_;
        if ($taxid ne "9606") {
            next;
        }
        if ($type !~ /^(protein-coding|ncRNA|pseudo|other|snoRNA|tRNA|rRNA|snRNA)$/) {
            next;
        }
        if ($symbol eq "-") {
            next;
        }
        if (${$r_symbol}{$symbol}) {
            print "WARNING: $symbol is duplicated symbol in gene_info file.\n";
        }
        ${$r_symbol}{$symbol} = $geneid;
        if ($synonyms eq "-") {
            next;
        }
        my @synonyms = split(/\|/, $synonyms);
        for my $synonym (@synonyms) {
            if (${$r_synonym}{$synonym}) {
                push @{${$r_synonym}{$synonym}}, $geneid;
            } else {
                ${$r_synonym}{$synonym} = [$geneid];
            }
        }
    }
    close(FILE);

    return 0;
}
