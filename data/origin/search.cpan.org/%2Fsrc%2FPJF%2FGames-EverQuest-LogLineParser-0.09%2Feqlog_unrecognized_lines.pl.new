## print all unrecognized lines in an EverQuest log file

use strict;
use warnings;

use Getopt::Std;

our ($opt_s);

getopts('s');

my ($rec_count, $total_count) = (0,0);

use Games::EverQuest::LogLineParser;

die "USAGE: perl eqlog_unrecognized_lines.pl <eqlog_file> [output_file]\n" unless @ARGV > 0;

my ($eqlog_file, $output_file) = @ARGV;

$output_file = defined $output_file ? $output_file : '-';

open (my $eqlog_fh,  $eqlog_file)     || die "$eqlog_file: $!";
open (my $output_fh, ">$output_file") || die "$output_file: $!";

my $start = time();

while (<$eqlog_fh>)
   {

   $total_count++;

   if (parse_eq_line($_))
      {
      $rec_count++;
      }
   else
      {
      print $output_fh $_;
      }

   }

my $total_secs = time() - $start;;

if ($opt_s)
   {
   my $rec_percent = 100 * $rec_count / $total_count;
   printf STDERR "    %% recognized: %.01f ($rec_count/$total_count)\n", $rec_percent;
   printf STDERR "lines per second: %d ($total_count/$total_secs)\n", $total_count / $total_secs;
   }

close $eqlog_fh;
close $output_fh;

__END__
=head1 NAME

eqlog_unrecognized_lines.pl - Perl script that prints lines from an EverQuest
log file, which are unparsable by L<Games::EverQuest::LogLineParser>.

=head1 SYNOPSIS

   ## output to STDOUT
   eqlog_unrecognized_lines.pl c:\everquest\eqlog_Soandso_server.txt

   ## output to file
   eqlog_unrecognized_lines.pl c:\everquest\eqlog_Soandso_server.txt eqlog.csv

   ## output statistics
   eqlog_unrecognized_lines.pl -s c:\everquest\eqlog_Soandso_server.txt eqlog.csv

=head1 DESCRIPTION

C<eqlog_eqlog_unrecognized_lines.pl> prints lines from an EverQuest log file,
which are unparsable by L<Games::EverQuest::LogLineParser>.

This is useful if in finding new line types which should be added to the
module.

=head1 OPTIONS

=over 4

=item C<-s> show stats on STDERR

   example:

          % recognized: 79.5 (686623/863465)
      lines per second: 7380 (863465/117)

=back

=head1 AUTHOR

Daniel B. Boorstein, E<lt>danboo@cpan.orgE<gt>

=head1 TO DO

=over 4

=item - show progress

=back

=head1 SEE ALSO

L<Games::EverQuest::LogLineParser>

=cut

