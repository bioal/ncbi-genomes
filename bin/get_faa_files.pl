#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
use HTTP::Date 'str2time', 'time2iso';
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM [assembly_summary.txt | http://...GCF_...]
-e: eukaryotes only
-o DIR: download directory
-q: check only and quit
-d: debug
";

my $COMMAND = "curl --max-time 100000 -LfsS";

my %OPT;
getopts('eo:qd', \%OPT);

my $PWD = `pwd`;
chomp $PWD;

if ($OPT{o}) {
    mkdir $OPT{o} unless -d $OPT{o};
    chdir $OPT{o} or die;
}

!@ARGV && -t and die $USAGE;
if (@ARGV) {
    if ($ARGV[0] =~ /(GCF_\S+)$/) {
        my $url = $ARGV[0];
        get_GCF($url);
        exit;
    } elsif ($ARGV[0] =~ /^\//) {
    } else {
        $ARGV[0] = "$PWD/$ARGV[0]";
    }
}

### Read assembly_summary.txt

my %EUKARYOTES = (
    "vertebrate_mammalian" => 1,
    "vertebrate_other" => 1,
    "invertebrate" => 1,
    "plant" => 1,
    "fungi" => 1,
    "protozoa" => 1,
    );

my %OTHERS = (
    "bacteria" => 1,
    "archaea" => 1,
    "viral" => 1,
    );

while (<>) {
    chomp;
    if (/^#/) {
        next;
    }

    my @f = split(/\t/, $_, -1);
    if (@f != 38) {
        die $_;
    }
    my $id = $f[0];
    my $url = $f[19];

    if ($OPT{e}) {
        my $group = $f[24];
        if ($EUKARYOTES{$group}) {
        } elsif ($OTHERS{$group}) {
            next;
        } else {
            die $_;
        }
    }
    get_GCF($url, $id);
}

################################################################################
### Function ###################################################################
################################################################################

sub get_GCF {
    my ($url, $id) = @_;

    $url =~ s/^https:\/\///;
    if ($url =~ /(GCF_\S+)$/) {
        if (-f "${1}_protein.faa.gz") {
            check_update($url, "${1}_protein.faa.gz", "${1}_protein.faa.gz");
        } elsif (-f "${1}_protein.faa") {
            check_update($url, "${1}_protein.faa.gz", "${1}_protein.faa");
        } else {
            if ($OPT{d}) {
                print "Download: $url/${1}_protein.faa.gz\n";
            } else {
                print "Download: ${1}_protein.faa.gz\n";
            }
            if (!$OPT{q}) {
                system "$COMMAND -OR $url/${1}_protein.faa.gz";
            }
        }
    } else {
        print STDERR "Cannot download $id ($url)\n";
    }
}

sub check_update {
    my ($url, $filename, $local_filename) = @_;

    my $ftp_time = `ftp.time $url/ $filename`;
    chomp($ftp_time);
    $ftp_time = time2iso(str2time($ftp_time, "GMT"));

    my $local_file_time = get_local_file_time($local_filename);
    if ($local_file_time eq $ftp_time) {
        if ($OPT{d}) {
            print "Already updated: $url/$filename\n";
        } else {
            print "Already updated: $filename\n";
        }
    } else {
        print "Update $filename: $local_file_time => new $ftp_time\n";
        if (!$OPT{q}) {
            system "$COMMAND -OR $url/$filename";
        }
    }
}

sub get_local_file_time {
    my ($file) = @_;

    my @stat = stat $file;
    my $time = time2iso($stat[9]);

    return $time;
}
