#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM [-a ALIGNER] FAA_FILE_1 FAA_FILE_2
-a ALIGNER: mmseqs-s8.5 or diamond-f (default)
-f: force execution (even if output files already exist)
";

my %OPT;
getopts('a:f', \%OPT);

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
print LOG "\n";
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
    if (-s "${pair}.tsv") {
        if ($OPT{f} or ! -s "${pair}.gene") {
            exec_with_time("cat ${pair}.tsv | map_to_gene.pl $PWD/$MAP_TO_GENE_DIR/$name1 $PWD/$MAP_TO_GENE_DIR/$name2 > ${pair}.gene 2> ${pair}.gene.err")
        }
    }
    if (-s "${pair}.gene") {
        if ($OPT{f} or ! -s "${pair}.homology") {
            exec_with_time("cat ${pair}.gene | select_max_score.pl > ${pair}.homology")
        }
    }
}

mean_bit_scores($NAME1, $NAME2);
mean_bit_scores($NAME2, $NAME2);
mean_bit_scores_intra($NAME1);
mean_bit_scores_intra($NAME2);

sub mean_bit_scores {
    my ($name1, $name2) = @_;

    if (-s "${name1}-${name2}.homology" and -s "${name2}-${name1}.homology") {
        if ($OPT{f} or ! -s "${name1}-${name2}.score") {
            exec_with_time("mean_bit_scores.pl ${name1}-${name2}.homology ${name2}-${name1}.homology > ${name1}-${name2}.score");
        }
    }
}

sub mean_bit_scores_intra {
    my ($name1) = @_;

    if (-s "${name1}-${name1}.homology") {
        if ($OPT{f} or ! -s "${name1}.score") {
            exec_with_time("mean_bit_scores_intra.pl ${name1}-${name1}.homology > ${name1}.score");
        }
    }
}

calculate_paralogy($NAME1, $NAME2);
calculate_paralogy($NAME2, $NAME1);

sub calculate_paralogy {
    my ($name1, $name2) = @_;

    if (-s "${name1}.score" and -s "${name1}-${name2}.score") {
        if ($OPT{f} or ! -s "${name1}.paralogy") {
            exec_with_time("calculate_paralogy.pl ${name1}.score ${name1}-${name2}.score > ${name1}.paralogy");
        }
    }
}

calculate_orthology($NAME1, $NAME2);
calculate_orthology($NAME2, $NAME1);

sub calculate_orthology {
    my ($name1, $name2) = @_;

    my $pair = "${name1}-${name2}";
    if (-s "${pair}.score" and -s "${name1}.paralogy") {
        if ($OPT{f} or ! -s "${name1}.orthology") {
            exec_with_time("calculate_orthology.pl ${pair}.score ${name1}.paralogy > ${name1}.orthology");
        }
    }
}

if (-s "${NAME1}-${NAME2}.score" and -s "${NAME1}.orthology" and -s "${NAME2}.orthology") {
    if ($OPT{f} or ! -s "${NAME1}-${NAME2}.ortholog") {
        exec_with_time("cat ${NAME1}-${NAME2}.score | eval_bidirectional.pl ${NAME1}.orthology ${NAME2}.orthology > ${NAME1}-${NAME2}.ortholog");
        system "cat 9606-10090.ortholog | compare_with_ncbi.pl -3 > /dev/null";
    }
}

close(LOG);

################################################################################
### Functions ##################################################################
################################################################################

sub exec_with_time {
    my ($command) = @_;

    print LOG "\n";
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
