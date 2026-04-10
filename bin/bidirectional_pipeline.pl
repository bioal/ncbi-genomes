#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM [-a ALIGNER] FAA_FILE_1 FAA_FILE_2
-a ALIGNER: mmseqs-s8.5 or diamond-f (default)
";

my %OPT;
getopts('a:', \%OPT);

my $ALIGNER = $OPT{a} || "diamond-f";

my $SEARCH_COMMAND;
if ($ALIGNER eq "mmseqs-s8.5") {
    $SEARCH_COMMAND = "mmseqs.pl -s 8.5";
} elsif ($ALIGNER eq "diamond-f") {
    $SEARCH_COMMAND = "diamond.pl -f";
} else {
    print STDERR "Unsupported aligner: $ALIGNER\n";
    print STDERR $USAGE;
    exit 1;
}

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($FILE1, $FILE2) = @ARGV;

my $DATE_TIME = `date "+%F %T"`;
chomp($DATE_TIME);

my $NAME1 = basename $FILE1;
my $NAME2 = basename $FILE2;
my $DIR_NAME = "${NAME1}-${NAME2}.${ALIGNER}";
my $MAP_TO_GENE_DIR = "geneid_refseq";

my $PWD = `pwd`;
chomp($PWD);
my $PATH1 = "$PWD/$FILE1";
my $PATH2 = "$PWD/$FILE2";

mkdir_with_check("$DIR_NAME");
chdir $DIR_NAME or die "Cannot change directory to $DIR_NAME: $!";

my $LOG_FILE_PATH = "$PWD/$DIR_NAME/log";
open(LOG, '>>', $LOG_FILE_PATH) or die "Cannot open log file $LOG_FILE_PATH: $!";
print LOG "[$DATE_TIME] Starting pipeline for $NAME1 and $NAME2 with $ALIGNER\n";

homology_search($PATH1, $PATH2);
homology_search($PATH2, $PATH1);
homology_search($PATH1, $PATH1);
homology_search($PATH2, $PATH2);

sub homology_search {
    my ($path1, $path2) = @_;

    my $name1 = basename $path1;
    my $name2 = basename $path2;
    my $pair = "${name1}-${name2}";
    if (! -s "${pair}.tsv") {
        exec_with_time("$SEARCH_COMMAND $path1 $path2");
    }
    if (-s "${pair}.tsv" and ! -s "${pair}.map_to_gene") {
        exec_with_time("cat ${pair}.tsv | map_to_gene.pl $PWD/$MAP_TO_GENE_DIR/$name1 $PWD/$MAP_TO_GENE_DIR/$name2 > ${pair}.map_to_gene 2> ${pair}.map_to_gene.err")
    }
    if (-s "${pair}.map_to_gene" and ! -s "${pair}.homolog") {
        exec_with_time("cat ${pair}.map_to_gene | select_max_score.pl > ${pair}.homolog")
    }
}

select_paralog($NAME1, $NAME2);
select_paralog($NAME2, $NAME1);

sub select_paralog {
    my ($name1, $name2) = @_;

    if (-s "${name1}-${name1}.homolog" and -s "${name1}-${name2}.homolog" and ! -s "${name1}.paralog") {
        exec_with_time("select_paralog.pl ${name1}-${name1}.homolog ${name1}-${name2}.homolog > ${name1}.paralog");
    }
}

select_ortholog($NAME1, $NAME2);
select_ortholog($NAME2, $NAME1);

sub select_ortholog {
    my ($name1, $name2) = @_;

    my $pair = "${name1}-${name2}";
    if (-s "${pair}.homolog" and -s "${name1}.paralog" and ! -s "${name1}.ortholog") {
        exec_with_time("select_ortholog.pl ${pair}.homolog ${name1}.paralog > ${name1}.ortholog");
    }
}

select_bidirectional_ortholog($NAME1, $NAME2);

sub select_bidirectional_ortholog {
    my ($name1, $name2) = @_;

    my $pair = "${name1}-${name2}";
    if (-s "${name1}.ortholog" and -s "${name2}.ortholog" and ! -s "${pair}.ortholog") {
        exec_with_time("eval_bidirectional.pl ${name1}.ortholog ${name2}.ortholog > ${pair}.ortholog");
    }
}

close(LOG);

################################################################################
### Functions ##################################################################
################################################################################

sub exec_with_time {
    my ($command) = @_;

    print LOG "\$ $command\n";

    my $start_time = time;
    system $command;
    my $end_time = time;
    my $elapsed_time = $end_time - $start_time;

    print LOG "$elapsed_time sec\n";
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        print STDERR "Command failed with exit code $exit_code\n";
        exit $exit_code;
    }
}

sub mkdir_with_check {
    my ($file_or_dir) = @_;

    system "mkdir -p $file_or_dir";
}
