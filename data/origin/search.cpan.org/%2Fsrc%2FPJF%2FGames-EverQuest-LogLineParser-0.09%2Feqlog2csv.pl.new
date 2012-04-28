## convert an EverQuest log file to a CSV (actually '|' separated) file

use strict;
use warnings;

use Games::EverQuest::LogLineParser;

die "USAGE: perl eqlog2csv.pl <eqlog_file> [output_file]\n" unless @ARGV > 0;

my ($eqlog_file, $output_file) = @ARGV;

$output_file = defined $output_file ? $output_file : '-';

open (my $eqlog_fh,  $eqlog_file)     || die "$eqlog_file: $!";
open (my $output_fh, ">$output_file") || die "$output_file: $!";

my @headers = all_possible_keys();

print $output_fh join('|', @headers), "\n";

while (<$eqlog_fh>)
   {

   my $line = parse_eq_line($_);

   if ($line)
      {

      no warnings 'uninitialized';

      $_ =~ tr/|//d for values %{ $line };

      print $output_fh join('|', @{ $line }{ @headers }), "\n";

      }

   }

close $eqlog_fh;
close $output_fh;

__END__
=head1 NAME

eqlog2csv.pl - Perl script that converts an EverQuest log file into a
CSV-like (separator is actually '|') file.

=head1 SYNOPSIS

   ## output to STDOUT
   eqlog2csv.pl c:\everquest\eqlog_Soandso_server.txt

      or

   ## output to file
   eqlog2csv.pl c:\everquest\eqlog_Soandso_server.txt eqlog.csv

=head1 DESCRIPTION

C<eqlog2csv.pl> converts the given EverQuest log file into a CSV-like file,
using the pipe (i.e., '|) character rather than the comma. Each parsable
line from the log file corresponds to a line in the output. The column
headers are the superset of all possible keys, as returned in the hash ref
frin C<Games::EverQuest::LogLineParser::parse_eq_line()>.

=head1 AUTHOR

Daniel B. Boorstein, E<lt>danboo@cpan.orgE<gt>

=head1 TO DO

=over 4

=item - user-specified separator character

=item - use Text::CSV_XS for proper CSV output

=back

=head1 SEE ALSO

L<Games::EverQuest::LogLineParser>

=cut

