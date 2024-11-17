#!/usr/bin/perl
#
# This script does the following task in a cross-platform maneer.
#
# ```
# for x in `grep -n COST_CHK /path/to/pcre_exec.c | grep -v 'COST_CHK(N)' | awk -F: '{print $1}'`; \
# do \
#      N=`expr $x + 100`; \
#      echo "case $N: goto L_LOOP_COUNT_${x};"; \
# done > /path/to/pcre_exec_loop_break_cases.inc
# ```
#
# I do not know Perl and to avoid adding a build dependency, I generated it
# with AI. It might not be entirely correct, however, it did the job.

use strict;
use warnings;
use Getopt::Long;

# Variables for command-line arguments
my $input_file;
my $output_file;

# Parse command-line arguments
GetOptions(
    'i=s' => \$input_file,
    'o=s' => \$output_file,
) or die "Usage: $0 -i <input_file> -o <output_file>\n";

# Check if both input and output files are provided
die "Usage: $0 -i <input_file> -o <output_file>\n" unless $input_file && $output_file;

# Read the input file
open my $in, '<', $input_file or die "Cannot open $input_file: $!";
my @lines = <$in>;
close $in;

# Find lines with COST_CHK but not COST_CHK(N)
my @line_numbers;
for my $i (0 .. $#lines) {
    if ($lines[$i] =~ /\bCOST_CHK\b(?!\(N\))/) {
        push @line_numbers, $i + 1;
    }
}

# Generate case statements
open my $out, '>', $output_file or die "Cannot open $output_file: $!";
for my $x (@line_numbers) {
    my $N = $x + 100;
    print $out "case $N: goto L_LOOP_COUNT_$x;\n";
}
close $out;

print "Generated ", scalar(@line_numbers), " case statements.\n";