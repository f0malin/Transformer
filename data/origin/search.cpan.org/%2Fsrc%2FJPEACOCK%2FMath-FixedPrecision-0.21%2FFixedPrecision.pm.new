#!/usr2/local/bin/perl -w
#
# PROGRAM:	Math::FixedPrecision.pm	# - 04/26/00 9:10:AM
# PURPOSE:	Perform precise decimal calculations without floating point errors
#
#------------------------------------------------------------------------------
#   Copyright (c) 2001 John Peacock
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#------------------------------------------------------------------------------
eval 'exec /usr2/local/bin/perl -S $0 ${1+"$@"}'
    if 0;

package Math::FixedPrecision;

require 5.005_02;
use strict;

use Exporter;
use Math::BigFloat(1.27);

use vars qw($VERSION @ISA @EXPORT
	    @EXPORT_OK %EXPORT_TAGS $PACKAGE
	    $accuracy $precision $round_mode $div_scale);

@ISA = qw(Exporter Math::BigFloat);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::FixedPrecision ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(

) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(

);
$VERSION = (qw$Revision: 2.1 $)[1]/10;
$PACKAGE = 'Math::FixedPrecision';

# Globals
$accuracy = $precision = undef;
$round_mode = 'even'; # Banker's rounding obviously
$div_scale  = 40;

# Preloaded methods go here.
############################################################################
sub new		#04/20/00 12:08:PM
############################################################################
{
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my $parent = ref($proto) && $proto;

	my $value	= shift || 0;	# Set to 0 if not provided
	my $decimal	= shift;
	my $radix	= 0;

	# Store the floating point value
	my $self = bless Math::BigFloat->new($value), $class;

	# Normalize the number to 1234567.890
	if ( ( $radix = length($value) - index($value,'.') - 1 ) != length($value) )	# Already has a decimal
	{
		if ( defined $decimal and $radix <= $decimal )	# higher precision overrides actual
		{
			$radix  = $decimal;
		}
		elsif ( defined $decimal )          # Too many decimal places
		{
			$self = $self->ffround(-1 * $decimal);
			$radix = undef;		# force the use of the asserted decimal
		}
	}
	else
	{
		$radix  = undef;			# infinite precision
	}

	if ( defined $radix )
	{
		$self->{_p} = - $radix;
	}
	elsif ( defined $decimal )
	{
		$self->{_p} = - $decimal;
	}
	else
	{
		$self->{_p} = undef;
	}

	return $self;
}	##new

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Math::FixedPrecision - Decimal Math without Floating Point Errors

=head1 SYNOPSIS

use Math::FixedPrecision;
$height  = Math::FixedPrecision->new(12.362);   # 3 decimal places
$width   = Math::FixedPrecision->new(9.65);     # 2 decimal places
$area    = $height * $width; # area is now 119.29 not 119.2933
$length  = Math::FixedPrecision->new("100.00"); # 2 decimal places
$section = $length / 9; # section is now 11.11 not 11.1111111...

=head1 DESCRIPTION

There are numerous instances where floating point math is unsuitable, yet the
data does not consist solely of integers.  This module employs new features
in Math::BigFloat to automatically maintain precision during math operations.
This is a convenience module, since all of the operations are handled by
Math::BigFloat internally.  You could do everything this module does by
setting some attributes in Math::BigFloat.  This module simplifies that
task by assuming that if you specify a given number of decimal places in
the call to new() then that should be the precision for that object going
forward.

Please examine assumptions you are operating under before deciding between this
module and Math::BigFloat.  With this module the assumption is that your data
is not very accurate and you do not want to overstate any resulting values;
Math::BigFloat can unintentially inflate the apparent accuracy of a calculation.

=head2 new(number[,precision])

The constructor accepts either a number or a string that looks like a number.
But if you want to enforce a specific precision, you either need to pass an
exact string or include the second term.  In other words, all of the following
variables have different precisions:

  $var1 = Math::FixedPrecision->new(10);
          # 10 to infinite decimals
  $var2 = Math::FixedPrecision->new(10,2);
          # 10.00 to 2 decimals
  $var3 = Math::FixedPrecision->new("10.000");
          # 10.000 to 3 decimals

All calculations will return a value rounded to the level of precision of
the least precise datum.  A number which looks like an integer (like $var1
above) has infinite precision (no decimal places).  This is important to note
since Perl will happily truncate all trailing zeros from a number like 10.000
and the code will get 10 no matter how many zeros you typed.  If you need to
assert a specific precision, you need to either explicitly state that like
$var2 above, or quote the number like $var3.  For example:

  $var4 = $var3 * 2; # 20.000 to 3 decimals
  $var5 = Math::FixedPrecision->new("2.00");
          # 2.00 to 2 decimals
  $var6 = $var3 * $var 5;
          # 20.00 to 2 decimals, not 3


=head2 EXPORT
None by default.


=head1 AUTHOR

John Peacock <jpeacock@rowman.com>

=head1 SEE ALSO

Math::BigFloat

=cut
