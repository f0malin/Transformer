package Date::Transform;

# Object Model
#
#	transform
#	+ source
#	+ filter
#	+ destination

# use lib 'C:/Documents and Settings/Christopher Brown/Desktop/CPAN';

use 5.006;
use strict;
use warnings;
use Carp;

# use Data::Dumper;
# use Benchmark qw(:all);
use Switch 'Perl5', 'Perl6';
use Tie::IxHash;
use POSIX qw(strftime);

use Date::Transform::Closures;      # Functions that create the closures.
use Date::Transform::Functions;     # Functions used in the closures
use Date::Transform::Extensions;    # Contains Extensions to Other Modules
use Date::Transform::Constants;     # Contains Constant Definitions

require Exporter;
use AutoLoader qw(AUTOLOAD);
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Date::Manip::Transform ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw( @CONSTANTS );

our $VERSION = '0.11';

# Preloaded methods go here.

sub new {

    my $type = shift;
    my $class = ref($type) || $type;
    my $self;

    # Arguments

    if ( scalar(@_) < 2 ) {    # Make sure that both arguments are given.
        carp("Both an input and an output arguments must be supplied.\n");
        die;
    }

    $self->{source}->{format}      = shift;
    $self->{destination}->{format} = shift;

    # Bless and return the object.
    bless $self, $class;

    $self->_initialize();

    return $self;

}

## SUBROUTINE: _initialize
##  Creates Transformation Function
sub _initialize {

    my $self = shift;

    # Expand Input & Output Formats
    #  From here on out we should deal exclusively with expanded formats.
    $self->{source}->{expanded_format} =
      _expand_compound_formats( $self->{source}->{format} );
    $self->{destination}->{expanded_format} =
      _expand_compound_formats( $self->{destination}->{format} );

    ## We can check the expanded output format for validity by making sure that none of the %_ are
    ## other than those acceptable to strftime function.  We can raise an error if they are detected.
    ##

    ## CREATE PLACE for POSIX ARRAY OF DATE
    ## sec, min, hour, mday, mon, year, wday
    ## {filter} will be the array passed to Posix::strftime
    my $ixhash_obj = Tie::IxHash->new();
    $ixhash_obj->STORE( 'format', $self->{destination}->{expanded_format} );
    $self->{filter}->{input} = $ixhash_obj;

    # Generate records of the formats and orders.
    # Retrieve input formats and order of formats.
    $self->{source}->{formats} =
      _parse_format_string( $self->{source}->{expanded_format} );
    $self->{destination}->{formats} =
      _parse_format_string( $self->{destination}->{expanded_format} );

    $self->_crosscheck
      ;    # Does the input data supply everything for necessary for the output.
    $self->_regexp;                 # Create regexp for matching.
    $self->_transform_functions;    # Create functions for mapping.

}    # END SUBROUTINE: _initialize

## SUBROUTINE: transform
##	Transforms the supplied date.
sub transform {

    my $self  = shift;
    my $input = shift;

    ## Set Defaults.
    ## my @array = $self->{filter}->{input}->Values;

    ## $matches will hold the values from the matched regular expression.
    my $matches = Tie::IxHash->new();

    ## SHOULD WE DO A  CASE INSENSITIVE MATCH -- Default: Yes.

    if ( $input =~ /$self->{filter}->{regexp}/i ) {

        ## TEMPORARILY DISABLE strict 'refs' SO THAT WE CAN USE $$n.
        no strict 'refs';

        ## Create Values from RegularExpression to Store in Cache.
        ## Foreach of the input formats,
        ##	name => value from regexp

        ## THIS IS THE SECOND MOST LIMITING STEP @ 1100/sec
        foreach ( $self->{source}->{formats}->Keys ) {
            $matches->Push( $_,
                ${ $self->{source}->{formats}->IndexFromKey($_) + 1 } );
        }

        ## REENABLE strict
        use strict 'refs';

        ## SET matches to object.
        $self->{filter}->{matches} = $matches;

        ## PERFORM EACH OF THE TRANSFORMATIONS
        ## THIS IS THE TIME LIMITING STEP @ 900/sec
        foreach my $transformation ( @{ $self->{filter}->{transformations} } ) {
            $self->$transformation;
        }

    }
    else {
        carp(
"No date matched input string, \"$input\".\nUsing Regular Expression: ",
            $self->{filter}->{regexp}, ".\n"
        );
    }

    return POSIX::strftime( $self->{filter}->{input}->Values );

}    # END SUBROUTINE: transform

## SUBROUTINE: _transform_functions
## 	Creates and stores the closures to be used in the transformation
sub _transform_functions {

    my $self = shift;

    my $required        = $self->{filter}->{requirements};
    my $supplied        = $self->{source}->{formats};
    my $filter          = $self->{filter}->{input};
    my $transformations = $self->{filter}->{transformations};

    ## 1. SECONDS
    if ( exists $required->{'S'} ) {

        # Generate second code.

        if ( $supplied->EXISTS('S') ) {

            my $f1       = mk_passthru('S');
            my $function = mk_set_filter_input( 'S', $f1 );

            push ( @{ $self->{filter}->{transformations} }, $function );

        }
        else {

            # SET DEFAULTS

        }

    }

    ## 2. MINUTES
    if ( $required->{'M'} ) {

        if ( $supplied->EXISTS('M') ) {

            my $f1       = mk_passthru('M');
            my $function = mk_set_filter_input( 'M', $f1 );

            push ( @{ $self->{filter}->{transformations} }, $function );

        }

    }

    ## 3. HOURS
    if ( exists $required->{'H'} ) {

        my $function;

        if ( $supplied->EXISTS('H') ) {

            my $f1 = mk_passthru('H');
            $function = mk_set_filter_input( 'H', $f1 );

        }
        elsif ( $supplied->EXISTS('k') ) {

            my $f1 = mk_passthru('k');
            $function = mk_set_filter_input( 'H', $f1 );

        }
        elsif ( $supplied->EXISTS('i') and $supplied->EXISTS('p') ) {

            my $f = \&iI_p_to_strftime_H;
            my $f1 = mk_function( $f, 'i', 'p' );
            $function = mk_set_filter_input( 'H', $f1 );

#= '$self->{filter}->{input}->[3] = $'	. $supplied->IndexFromKey('H');
#$function = '$self->{filter}->{input}->[3] = $'	. $supplied->IndexFromKey('H') . ' + 12' if ($ 0);

        }

        push ( @{ $self->{filter}->{transformations} }, $function );
    }

    ## 4. MONTHDAY
    if ( exists $required->{'d'} ) {

        my $function;

        if ( $supplied->EXISTS('d') ) {

            my $f1 = mk_passthru('d');
            $function = mk_set_filter_input( 'd', $f1 );

        }
        elsif ( $supplied->EXISTS('e') ) {

            my $f1 = mk_passthru('e');
            $function = mk_set_filter_input( 'd', $f1 );

        }

        push ( @{ $self->{filter}->{transformations} }, $function );

    }

    ## 5. MONTH
    if ( exists $required->{'m'} ) {

        my $function;

        if ( $supplied->EXISTS('m') ) {

            my $f = \&m_to_strftime_m;
            my $f1 = mk_function( $f, 'm' );
            $function = mk_set_filter_input( 'm', $f1 );

        }
        elsif ( $supplied->EXISTS('f') ) {

            my $f = \&m_to_strftime_m;
            my $f1 = mk_function( $f, 'f' );
            $function = mk_set_filter_input( 'm', $f1 );

        }
        elsif ( $supplied->EXISTS('b') ) {

            my $f = \&bh_to_strftime_m;
            my $f1 = mk_function( $f, 'b' );
            $function = mk_set_filter_input( 'm', $f1 );

        }
        elsif ( $supplied->EXISTS('h') ) {

            my $f = \&bh_to_strftime_m;
            my $f1 = mk_function( $f, 'h' );
            $function = mk_set_filter_input( 'm', $f1 );

        }
        elsif ( $supplied->EXISTS('B') ) {

            my $f = \&B_to_strftime_m;
            my $f1 = mk_function( $f, 'B' );
            $function = mk_set_filter_input( 'm', $f1 );

        }

        push ( @{ $self->{filter}->{transformations} }, $function );

    }

    ## 6. YEAR
    if ( exists $required->{'Y'} ) {

        my $function;

        if ( $supplied->EXISTS('y') ) {

            my $f1 = mk_passthru('y');
            $function = mk_set_filter_input( 'y', $f1 );

        }
        elsif ( $supplied->EXISTS('Y') ) {

            my $f = \&Y_to_strftime_y;
            my $f1 = mk_function( $f, 'Y' );
            $function = mk_set_filter_input( 'y', $f1 );
        }

        push ( @{ $self->{filter}->{transformations} }, $function );

    }

    return 1;

}

## SUBROUTINE: _regexp
## 	Creates the regexp used in the transformation
sub _regexp {

    ## Converts input format into regular expression format.
    my $self = shift;

    my $regexp = $self->{source}->{expanded_format};

    # Replace Special Characters
    $regexp =~ s/\%n/\\n/g;
    $regexp =~ s/\%t/\\t/g;
    $regexp =~ s/\%\%/\\%/g;
    $regexp =~ s/\%\+/\\+/g;

    foreach ( $self->{source}->{formats}->Keys ) {
        my $re_replacement = "(" . &_re($_) . ")";
        $regexp =~ s/\%($_)/$re_replacement/eg;
    }

    $self->{filter}->{regexp} = $regexp;

    # return $regexp;

}    # END SUBROUTINE: _regexp

## SUBROUTINE: _crosscheck
## 	ensures that the input string supplies all the necessary information
## 	for the requested output. Requires some complex logic (not implemented yet.)
sub _crosscheck {

# Checks to see if the necessary data elements the input_format supplies enough data.

    my $self = shift;

    # my %strftime_requirements;
    # my @req;

    # What are the output requirements.
    my %or = _strftime_requirements( $self->{destination}->{formats}->Keys );
    $self->{filter}->{requirements} = \%or;

    # What are the input supplied.
    my %is = _strftime_requirements( $self->{source}->{formats}->Keys );

    # $self->{source}->{supplied} = \%is;

    # Crosscheck outputs requested vs inputs supplied.
    #my %is = map { $_ => 1 } @is;

    foreach my $or ( sort keys %or ) {

        if ( !$is{$or} ) {
            carp
"WARNING: %$or is required by the output, but not supplied by the input.\n";

            # die("\n") unless ( $is{$or} );
        }

    }

}

## SUBROUTINE: _parse_format_string
##	Given a date string => href of elements in the string, aref of order of elements
##		Because we reverse the format string ... walking it backwards ... if an element
##		appears more than once, the REAL first occurence will be captured.
sub _parse_format_string {

    # Format String => href Elements in Sting, aref order of elements

    my $format = shift;
    my $index  = 0;

    my $ixhash_obj = Tie::IxHash->new();

    $format = reverse($format);    # REVERSE THE ORDER OF FORMAT.

    # my $elements;
    # my $order;

    my ( $r1, $r2 );

    $r1 = chop($format);

    while ($format) {

        $r2 = $r1;
        $r1 = chop($format);

        # Test for format field.
        if ( $r2 eq '%' ) {

    # $elements->{$r1} =  undef;  # These will become storage recepticles later.
    # push @{$order}, $r1;

# Since date information might appear twice in the string, we only want to take the first instance.
# next if ( $ixhash_obj->[0]->{$r1} );
# Make sure to put the new formats at the front of object.
            $ixhash_obj->Push( $r1 => $index );
            $r1 = chop($format);

            $index++;
        }

    }

    return $ixhash_obj;

}

########################

## SUBROUTINE: _expand_compound_formats
## 	Expands compound formats to full formats.
sub _expand_compound_formats {

    my $format = shift;
    my ( $expansion, $new_format );

    $format = reverse $format;

    my ( $r1, $r2 );
    $r1 = chop $format;

    while ($format) {

        $r2 = $r1;
        $r1 = chop($format);

        my $expansion;

        # Test for format field.
        if ( $r2 eq '%' ) {

            given($r1) {

                # COMPUND FORMATS

                when [ "T", "X" ] { $expansion = "%H:%M:%S"; }
                when "c" { $expansion = "%a %b %e %H:%M:%S %z %Y"; }
                when [ "C", "u" ] { $expansion = "%a %b %e %H:%M:%S %z %Y"; }
                when "g" { $expansion = "%a, %d %b %Y %H:%M:%S %z"; }
                when [ "D", "x" ] { $expansion = "%m/%d/%y"; }

                when "r" { $expansion = "%I:%M:%S %p"; }
                when "R" { $expansion = "%H:%M"; }
                when "V" { $expansion = "%m%d%H%M%y"; }
                when "Q" { $expansion = "%Y%m%d"; }
                when "q" { $expansion = "%Y%m%d%H%M%S"; }
                when "P" { $expansion = "%Y%m%d%H:%M:%S"; }
                when "F" { $expansion = "%A, %B %e, %Y"; }
                when "J" { $expansion = "%G-%W-%w"; }
                when "K" { $expansion = "%Y-%j"; }

# when ""	{ $re = '' } # MORE.
# when "l"	{ $re = "[" . join( ' ', _re(b,e,R) ) . '|' . join( ' ', _re(b,e,Y) ) . "]" }
# Omitted for now, but logic can be included to solve the problem.

                # Don't expand non compound factors
                else { $expansion .= $r2 . $r1; }

            }    # End SWITCH

            $r1 = chop($format);

        }
        else {

            $expansion = $r2;

        }    # END if

        $new_format .= $expansion;

    }    # END format WHILE

    return $new_format;

}

## SUBROUTINE: _strftime_requirements
##	Given a series of formats that are requested,
## 	This function determines what is required by
##	strftime to suppy those requirements.
sub _strftime_requirements {

    # OUTPUT REQUIREMENTS
    # my $format;
    my @formats = @_;
    my @req;

    foreach my $format (@formats) {

        given($format) {

            # Year
            when [ "Y", "y", "G", "L" ] { push ( @req, 'Y' ); }

            # Month
            when [ "m", "f", "b", "h", "B" ] { push ( @req, 'm' ); }

            # Week/Day of the year, Day of the week
            when [ "U", "W", "j", "v", "a", "A", "w" ] {
                push ( @req, 'Y', 'm', 'd' );
            }

            # Day of the Month
            when [ "d", "e", "E" ] { push ( @req, 'd' ); }

            # Hour
            when [ "H", "k", "i", "l", "p" ] { push ( @req, 'H' ); }

            # Minute
            when ["M"] { push ( @req, 'M' ); }

            # Second
            when ["S"] { push ( @req, 'S' ); }

        }    # END SWITCH BLOCK

    }    # END @formats LOOP

    # Remove duplicates from requirements
    my %req = map { $_ => 1 } @req;

    return %req;    # return (keys(%req));

}

sub _re {

    # Generate regular expression for the given format(s)
    # In general the regular expressions should be
    # restrictive and fast.
    #

    my $format = shift;

    # my $regexp;

    my $re;

    given($format) {

        # YEAR
        when "y" { $re = '\d{2}'; }
        when [ "Y", "G", "L" ] { $re = '\d{4}'; }

        #Month
        when "m" { $re = '[01]\d'; }
        when "f" { $re = '\d{1}|1[0-2]'; }
        when [ "b", "h" ] {
            $re = 'Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec';
        }
        when "B" {
            $re =
'January|February|March|April|May|June|July|August|September|October|November|December';
        }
        when [ "U", "W" ] { $re = '[0-5]\d'; }

        # Day
        when "j" { $re = '[0-3]\d{2}'; }
        when "d" { $re = '[0-3]\d'; }
        when "e" { $re = '[ |0|1|2|3]\d'; }
        when "v" { $re = ' S| M| T| W|Th|F|Sa'; }
        when "a" { $re = 'Sun|Mon|Tue|Wed|Thu|Fri|Sat'; }
        when "A" {
            $re = 'Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday';
        }
        when "w" { $re = '1-7'; }
        when "E" { $re = '\d{1,2}st|nd|rd|th'; }

        # Hours
        when "H" { $re = '[0-2]\d'; }
        when "k" { $re = '[ 12]\d'; }
        when "i" { $re = '[ 1]\d'; }
        when "I" { $re = '[01]\d'; }
        when "p" { $re = 'AM|PM'; }

        when [ "M", "S" ] { $re = '[0-6]\d'; }

        else { carp "No Regular Expression found for POSIX format -- $format"; }

    }    # END case BLOCK

    return $re

}    # END SUBROUTINE _re

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__;

# Below is stub documentation for your module. You better edit it!

=pod

=head1 NAME

Date::Transform - Efficiently transform dates.

=head1 SYNOPSIS

  use Date::Transform;
  
  $input_format 	= '%x';        # e.g. 01/01/2001
  $output_format 	= '%b %d, %Y'; # e.g. January 1, 2001 
  
  $dt = new Date::Transform( 
		$input_format,
		$output_format
  )

  $input_1   = '04/15/2001';  
  $input_2   = '10/31/2001';

  $output_1  = $dt->transform($input_1); # Apr 15, 2001	
  $output_2  = $dt->transform($input_2); # Oct 31, 2001


=head1 DESCRIPTION

Sullivan Beck's L<Date::Manip|Date::Manip> is an excellent module for performing 
operations involving dates.  However, because of its extraordinary flexibility, 
it is slow when much date parsing is needed.  

I found that more than 95% of my operations using dates required repeated 
operations of going from YYYY-mm-dd to mm/dd/YYYY.  This occurs often
when changing an array or column of dates from one format to another.  While 
L<Date::Manip|Date::Manip> C<UnixDate> function can do this, its flexibility nature causes it to be slower than
often needed.  

When the input format is specified beforehand, parsing of the input date becomes much
easier and the speed of the transformation can be greatly enhanced.  B<Date::Transform> 
provides this by writing a custom algorithm maximized to the specific operation.  
While a considerable initialization is required to creation the transformation code,
the resultant transformation are typically 300-500% faster than C<UnixDate>.  

=head1 METHODS

=over 4

=item new( $input_format, $output_format )

Creates a new B<Date::Manip::Transform> object and initializes the C<transform> function.

C<$input_format> is treated as a regular expression for matching. Thus,  

new('%b %d, %Y', '%Y-%m-%d') matches and transforms:
 
'I came to California on Oct 15, 1992' ==> 'I came to California on 1992-10-15.


See L<"SUPPORTED FORMATS"> for details on the supported format types.

All formats must be proceeded by C<%>.

=item transform( $date )

Transforms supplied C<$date> value in the $input_format to the C<$output_format> as 
specified when the Date::Transform object was created.

=back

=head1 SUPPORTED FORMATS

 %[A a B b c d H I J M m p S U w W x X Y Z]

Please see L<Date::Manip/"UnixDate"> or L<Posix>.

=head1 NOTES

I would be happy to have this incorporated directly into Sullivan Beck's Date::Manip module.

=head1 EXPORT

None by default.

=head1 TODO

  + Speed transformation where a rearrangement of numbers is the only thing necessary
  + Implement a default using user parameters or localtime()
  + Multiple language support.
  + Incoporate %l format.
  + Allow specification of whether the date is to be replaced or simple extracted and transformed.
  + Specify Date Constants

=head1 AUTHOR

Christopher Brown, L<chris.brown@cal.berkeley.edu>

=head1 COPYRIGHT

Copyright (c) 2003 Christopher T. Brown.

=head1 SEE ALSO

L<perl>, 
L<Date::Manip>, 
L<Switch>, 
L<Posix>


=cut
