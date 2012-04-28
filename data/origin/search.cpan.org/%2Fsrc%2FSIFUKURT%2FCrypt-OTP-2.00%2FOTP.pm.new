#-------------------------------------------------------------------------#
# Crypt::OTP
#       Date Written:   07-Jul-2000 02:58:42 PM
#       Last Modified:  04-Sep-2002 01:29:36 PM
#       Author:    Kurt Kincaid
#       Copyright (c) 2002, Kurt Kincaid
#           All Rights Reserved
#
# NOTICE: This is free software and may be modified and/or redistributed
#         under the same terms as Perl itself.
#-------------------------------------------------------------------------#

package Crypt::OTP;

use strict;
use vars qw/ $VERSION @ISA @EXPORT @EXPORT_OK $pad_text $class $pad $mode $oo /;

require Exporter;

@ISA = qw/ Exporter /;

$VERSION = '2.00';
@EXPORT = qw/ OTP /;

sub new {
    ( $class, $pad, $mode ) = @_;
    my $self = bless {}, $class;
    if ( $mode ) {
        $pad_text = $pad;
    } else {
        local $/ = undef;
        open( PAD, $pad ) || return $!;
        $pad_text = <PAD>;
        close( PAD );
    }
    $oo = 1;
    return $self;
}

sub OTP {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $pad, $message );
    if ( $oo ) {
        ( $message, $mode ) = @_;
    } else {
        ( $pad, $message, $mode ) = @_;
    }
    unless ( $oo ) {
        if ( $mode ) {
            $pad_text = $pad;
        } else {
            local $/ = undef;
            open( PAD, $pad ) || return $!;
            $pad_text = <PAD>;
            close( PAD );
        }
    }

    while ( length( $pad_text ) < length( $message ) ) {
        $pad_text .= $pad_text;
    }
    my @message = split ( //, $message );
    my @pad     = split ( //, $pad_text );
    my $cipher;

    for ( my $i = 0 ; $i <= $#message ; $i++ ) {
        $cipher .= pack( 'C', unpack( 'C', $message[ $i ] ) ^ unpack( 'C', $pad[ $i ] ) );
    }
    return $cipher;
}

1;

__END__

=head1 NAME

Crypt::OTP - Perl implementation of the One Time Pad (hence, OTP) encryption method.

=head1 SYNOPSIS

# OO Interface

  use Crypt::OTP;
  $ref = Crypt::OTP->new( "padfile" );
  $cipher = $ref->OTP( $message );
    or
  $cipher = $ref->OTP( $message, $mode );
  
# Functional Interface

  use Crypt::OTP;
  $cipher = Crypt::OTP( $pad, $message );
    or
  $cipher = Crypt::OTP( $pad, $message, $mode );

=head1 DESCRIPTION

The One Time Pad encryption method is very simple, and impossible to crack without the actual pad file against which the to-be-encrypted message is XOR'ed.  Encryption and decryption are performed using excactly the same method, and the message will decrypt correctly only if the same pad is used in decryption as was use in encryption.

The safest method of use is to use a large, semi-random text file as the pad, like so:

$ciphertext = OTP( "my_pad.txt", $message );

However, I've also implemented a second method which does not rely on an external pad file, though this mathod is substantially less secure.

$less_secure = OTP( "This text takes the place of my pad file", $message, 1 );

In this example, the "1" instructs the OTP sub-routine to use the contents of the first element as the pad, rather than the default method which is to use the first element as the name of the external pad file.

If the file specified using the first method does not exist, OTP returns zero.  In all other cases, OTP returns the XOR'ed message.

A few important points should be made about key management. First and most importantly, it should be noted that using the method where the pad is passed as a string (i.e., setting the mode to a non-zero value) is tremendously unsecure unless you use a non-repeating sequence that is at least as long as the message to be encrypted. I've had some lively debate with others on this point, but I stand firmly by the notion that key management is left as an exercise for the user. The purpose of this module is to provide One Time Pad encryption, not to provide key management for same, which is, unquestionably, a separate task. As with any encryption method, IF YOU USE IT IN AN UNSECURE FASHION, IT WILL BE UNSECURE. In any case, best practice is to use a pad that contains a pseudo-random set of data with a period greater than or equal to the length of the message to be encrypted. Why "pseudo-random"? Simple. Any random number generator (i.e., the rand() function in perl) that isn't specifically stated to be cryptographically secure, will eventually repeat its sequence of random numbers. As such, if for example your random number generator starts repeating its sequence after, say, 100 numbers, messages of less than 100 characters will be fairly secure. However, encrypted messages greater than 100 characters would be considered weak, because they would be encrypted with a pad that displays a repeating sequence. If you are uncomfortable with doing your own key management, then this is probably not the module for you. If you take proper precautions with your pad/key, Crypt::OTP will serve you in good stead. Use this module at your own risk, and use the utmost care with managing your keys.

=head1 AUTHOR

Kurt Kincaid, sifukurt@yahoo.com

=head1 SEE ALSO

perl(1).

=cut

