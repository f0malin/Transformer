## report on the counts of line types in an EverQuest log file

use strict;
use warnings;

use Getopt::Std;

our ($opt_n);

getopts('n');

use Games::EverQuest::LogLineParser;

die "USAGE: perl eqlog_line_type_frequency.pl <eqlog_file> [output_file]\n" unless @ARGV > 0;

my ($eqlog_file, $output_file) = @ARGV;

$output_file = defined $output_file ? $output_file : '-';

open (my $eqlog_fh,  $eqlog_file)     || die "$eqlog_file: $!";

my %freq;

while (<$eqlog_fh>)
   {

   (my $line = parse_eq_line($_)) || next;

   $freq{ $line->{'line_type'} } ++;

   }

close $eqlog_fh;

open (my $output_fh, ">$output_file") || die "$output_file: $!";

if ($opt_n)
   {
   for (sort { $freq{$a} <=> $freq{$b} } keys %freq)
      {
      printf $output_fh "   %-24s => %s\n", $_, $freq{$_};
      }
   }
else
   {
   for (sort keys %freq)
      {
      printf $output_fh "   %-24s => %s\n", $_, $freq{$_};
      }
   }

close $output_fh;

__END__
=head1 NAME

eqlog_line_type_frequency.pl - Perl script that reports the counts of each
type in an EverQuest log file.

=head1 SYNOPSIS

   ## output to STDOUT
   eqlog_line_type_frequency.pl c:\everquest\eqlog_Soandso_server.txt

   ## output to file
   eqlog_line_type_frequency.pl c:\everquest\eqlog_Soandso_server.txt eqlog.csv

   ## output sorted by frequency
   eqlog_line_type_frequency.pl -n c:\everquest\eqlog_Soandso_server.txt eqlog.csv

=head1 DESCRIPTION

C<eqlog_line_type_frequency.pl> counts the number of occurences of each line
type in the given EverQuest log file.

This is useful for the module author in determining the order in which line
types should be tested.

=head2 Sample output:

   BUY_ITEM                 => 24
   CORPSE_MONEY             => 141
   CRITICAL_SCORE           => 2852
   DAMAGE_OVER_TIME         => 2784
   DAMAGE_SHIELD            => 11119
   DIRECT_DAMAGE            => 11920
   ENTERED_ZONE             => 730
   FACTION_HIT              => 2033
   FORGET_SPELL             => 1276
   GAIN_EXPERIENCE          => 2813
   LOCATION                 => 230
   LOOT_ITEM                => 2194
   MELEE_DAMAGE             => 403297
   MEMORIZE_SPELL           => 1414
   MOB_MISSES_YOU           => 6799
   MOB_REPELS_HIT           => 14025
   OTHER_CASTS              => 58252
   OTHER_SAYS               => 16932
   OTHER_SHOUTS             => 1694
   OTHER_TELLS_GROUP        => 23808
   OTHER_TELLS_YOU          => 1102
   PLAYER_HEALED            => 1865
   PLAYER_LISTING           => 4918
   SAYS_OOC                 => 6746
   SELL_ITEM                => 309
   SKILL_UP                 => 135
   SLAIN_BY_OTHER           => 2171
   SLAIN_BY_YOU             => 1404
   SPEND_ADVENTURE_POINTS   => 3
   SPLIT_MONEY              => 150
   TRACKING_MOB             => 279
   WIN_ADVENTURE            => 34
   YOUR_SPELL_RESISTED      => 769
   YOUR_SPELL_WEARS_OFF     => 248
   YOU_CAST                 => 6328
   YOU_FIZZLE               => 784
   YOU_MISS_MOB             => 71248
   YOU_REPEL_HIT            => 2676
   YOU_SLAIN                => 15
   YOU_TELL_GROUP           => 4329
   YOU_TELL_OTHER           => 965


=head1 OPTIONS

=over 4

=item C<-n> print sorted by number of lines

=back

=head1 AUTHOR

Daniel B. Boorstein, E<lt>danboo@cpan.orgE<gt>

=head1 TO DO

=over 4

=item - user-specified sort order (key-alpha vs value numeric)

=back

=head1 SEE ALSO

L<Games::EverQuest::LogLineParser>

=cut

