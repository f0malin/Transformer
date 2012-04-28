package DateTime::Format::HTTP;
use strict;
use warnings;
use vars qw( $VERSION );

$VERSION = '0.40';

use DateTime;
use HTTP::Date qw();

use vars qw( @MoY %MoY);
@MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@MoY{@MoY} = (1..12);

sub format_datetime
{
    my ($self, $dt) = @_;
    $dt = DateTime->now unless defined $dt;
    $dt = $dt->clone->set_time_zone( 'GMT' );
    return $dt->strftime( "%a, %d %b %Y %H:%M:%S GMT" );
}


sub parse_datetime
{
    my ($self, $str, $zone) = @_;
    local $_;
    die "No input string!" unless defined $str;

    # fast exit for strictly conforming string
    if ($str =~ /^
	[SMTWF][a-z][a-z],
	\ (\d\d)
	\ ([JFMAJSOND][a-z][a-z])
	\ (\d\d\d\d)
	\ (\d\d):(\d\d):(\d\d)
	\ GMT$/x) {
	return DateTime->new(
	    day => $1,
	    month => $MoY{$2},
	    year => $3,
	    hour => $4,
	    minute => $5,
	    second => $6,
	    time_zone => 'GMT'
	);
    }

    my %d = $self->_parse_date($str);

    unless (defined $d{time_zone})
    {
	$d{time_zone} = defined $zone ? $zone : 'floating';
    }

    my $frac = $d{second}; $frac -= ($d{second} = int($frac));
    my $nano = 100_000_000 * $frac; $d{nanosecond} = int($nano);
    return DateTime->new( %d );
}


sub _parse_date
{
    my ($self, $str) = @_;
    my @fields = qw( year month day hour minute second time_zone );
    my %d;
    my @values = HTTP::Date::parse_date( $str );
    die "Could not parse date [$str]\n" unless @values;
    @d{@fields} = @values;

    if (defined $d{time_zone}) {
	$d{time_zone} = "GMT" if $d{time_zone} =~ /^(Z|GMT|UTC?|[-+]?0+)$/ix;
    }

    return %d;
}


sub format_iso
{
    my ($self, $dt) = @_;
    $dt = DateTime->now unless defined $dt;
    sprintf("%04d-%02d-%02d %02d:%02d:%02d",
	$dt->year, $dt->month, $dt->day,
	$dt->hour, $dt->min, $dt->sec
    );
}


sub format_isoz
{
    my ($self, $dt) = @_;
    $dt = DateTime->now unless defined $dt;
    $dt = $dt->clone->set_time_zone( 'UTC' );
    sprintf("%04d-%02d-%02d %02d:%02d:%02dZ",
	$dt->year, $dt->month, $dt->day,
	$dt->hour, $dt->min, $dt->sec
    );
}

1;


__END__

=head1 NAME

DateTime::Format::HTTP - Date conversion routines

=head1 SYNOPSIS

    use DateTime::Format::HTTP;

    my $class = 'DateTime::Format::HTTP';
    $string = $class->format_datetime($dt); # Format as GMT ASCII time
    $time = $class->parse_datetime($string); # convert ASCII date to machine time

=head1 DESCRIPTION

This module provides functions that deal the date formats used by the
HTTP protocol (and then some more).

=head1 METHODS

=head2 parse_datetime( $str [, $zone] )

The parse_datetime() function converts a string to machine time. It throws
an error if the format of $str is unrecognized, or the time is outside
the representable range. The time formats recognized are listed below.

The function also takes an optional second argument that specifies the
default time zone to use when converting the date. This parameter is
ignored if the zone is found in the date string itself. If this
parameter is missing, and the date string format does not contain
any zone specification, then the floating time zone is used.

The zone should be one that is recognized by L<DateTime::TimeZone>.

Actual parsing is done with the L<HTTP::Date> module. At the time of
writing it supports the formats listed next. Consult that module's
documentation in case the list has been changed.

 "Wed, 09 Feb 1994 22:23:32 GMT"       -- HTTP format
 "Thu Feb  3 17:03:55 GMT 1994"        -- ctime(3) format
 "Thu Feb  3 00:00:00 1994",           -- ANSI C asctime() format
 "Tuesday, 08-Feb-94 14:15:29 GMT"     -- old rfc850 HTTP format
 "Tuesday, 08-Feb-1994 14:15:29 GMT"   -- broken rfc850 HTTP format

 "03/Feb/1994:17:03:55 -0700"   -- common logfile format
 "09 Feb 1994 22:23:32 GMT"     -- HTTP format (no weekday)
 "08-Feb-94 14:15:29 GMT"       -- rfc850 format (no weekday)
 "08-Feb-1994 14:15:29 GMT"     -- broken rfc850 format (no weekday)

 "1994-02-03 14:15:29 -0100"    -- ISO 8601 format
 "1994-02-03 14:15:29"          -- zone is optional
 "1994-02-03"                   -- only date
 "1994-02-03T14:15:29"          -- Use T as separator
 "19940203T141529Z"             -- ISO 8601 compact format
 "19940203"                     -- only date

 "08-Feb-94"         -- old rfc850 HTTP format    (no weekday, no time)
 "08-Feb-1994"       -- broken rfc850 HTTP format (no weekday, no time)
 "09 Feb 1994"       -- proposed new HTTP format  (no weekday, no time)
 "03/Feb/1994"       -- common logfile format     (no time, no offset)

 "Feb  3  1994"      -- Unix 'ls -l' format
 "Feb  3 17:03"      -- Unix 'ls -l' format

 "11-15-96  03:52PM" -- Windows 'dir' format

The parser ignores leading and trailing whitespace.  It also allow the
seconds to be missing and the month to be numerical in most formats.

If the year is missing, then we assume that the date is the first
matching date I<before> current month.  If the year is given with only
2 digits, then parse_date() will select the century that makes the
year closest to the current date.

=head2 format_datetime()

The C<format_datetime()> method converts a L<DateTime> to a string. If
the function is called without an argument, it will use the current
time.

The string returned is in the format preferred for the HTTP protocol.
This is a fixed length subset of the format defined by RFC 1123,
represented in Universal Time (GMT).  An example of a time stamp
in this format is:

   Sun, 06 Nov 1994 08:49:37 GMT

=head2 format_iso( [$time] )

Same as format_datetime(), but returns a "YYYY-MM-DD hh:mm:ss"-formatted
string representing time in the local time zone. It is B<strongly>
recommended that you use C<format_isoz> or C<format_datetime> instead
(as these provide time zone indication).

=head2 format_isoz( [$dt] )

Same as format_iso(), but returns a "YYYY-MM-DD hh:mm:ssZ"-formatted
string representing Universal Time.

=head1 THANKS

Gisle Aas (GAAS) for writing L<HTTP::Date>.

Iain, for never quite finishing C<HTTP::Date::XS>.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

Alternatively, log them via the CPAN RT system via the web or email:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime%3A%3AFormat%3A%3AHTTP
    bug-datetime-format-http@rt.cpan.org

This makes it much easier for me to track things and thus means
your problem is less likely to be neglected.

=head1 LICENCE AND COPYRIGHT

Copyright Iain Truskett, 2003. All rights reserved.
Sections of the documentation Gisle Aas, 1995-1999.
Changes since version 0.35 copyright David Rolsky, 2004.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.000 or,
at your option, any later version of Perl 5 you may have available.

The full text of the licences can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> as supplied with Perl 5.8.1 and later.


=head1 AUTHOR

Originally written by Iain Truskett <spoon@cpan.org>, who died on
December 29, 2003.

Maintained by Dave Rolsky <autarch@urth.org> and Christiaan Kras <ckras@cpan.org>

=head1 SEE ALSO

C<datetime@perl.org> mailing list.

http://datetime.perl.org/

L<perl>, L<DateTime>, L<HTTP::Date>, L<DateTime::TimeZone>.

=cut

