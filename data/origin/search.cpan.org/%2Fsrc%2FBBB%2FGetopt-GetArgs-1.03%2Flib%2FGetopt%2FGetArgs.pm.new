#!/usr/bin/perl -w

package Getopt::GetArgs;

use strict;
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(GetArgs);
$VERSION = "1.03";

=head1 NAME

GetArgs - Perl module to allow enhanced argument passing,
including passing of case-insensitive named arguments as
well as positioned arguments.

=head1 SYNOPSIS

  sub WHATEVER {
    my @DEFAULT_ARGS =
      ( Content => "Default content",
        Verbose => 0 
        );
    my %ARGS=GetArgs(@_,@DEFAULT_ARGS);
    # do some stuff with $ARGS{Content}
    # show all kinds of detail if $ARGS{Verbose}
  }

  # a simple call to WHATEVER
  WHATEVER( "Just deal with my content" );

  # a flexible call to WHATEVER
  WHATEVER({ verbose => 1,
             content => "This is my content",
           });

=head1 DESCRIPTION

GetArgs needs to know 
  * what your subroutine was passed, 
  * and what it expected to be passed.  
  * If you like, you can also supply default values to use when an argument is not passed.  
  
Using this information, GetArgs will create a hash of arguments for you to use throughout your subroutine.  Using GetArgs has several advantages:

  1) Calls to your subroutine can pass named arguments, making the code more readable.
  2) If it's easier to pass a list of arguments as you normally would, that's fine.  
  3) With GetArgs your use of arguments in your subroutine code is more readable.
  4) Your subroutines are no longer limited in the number of arguments they expect.
  5) Arguments can be passed in any order (if passed inside the hash ref), thus 
     only the arguments relevant to that call need to be passed--unnecessary 
     arguments can be ignored.
  6) Case is not important, as GetArgs matches argument names case insensitively.

=head1 AUTHOR

Special thanks to Sam Mefford who helped design and
wrote most of the code for the original version.

Much polishing in preparation for release to CPAN
was performed by Earl Cahill. (earl@cpan.org)

Maintained by Rob Brown (rob@roobik.com)

=head1 COPYRIGHT

Copyright (c) 2001, Rob Brown.  All rights reserved.
Getopt::GetArgs is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: GetArgs.pm,v 1.4 2001/06/08 06:26:44 rob Exp $

=cut

sub GetArgs (\@\@) {

  ### set up variables to take the referenced arguments
  my ($PASSED_ARGS_ref,$DEFAULT_ARGS_ref) = @_;
  my (@arg_names,%default_values,$arg_name,$expect_name);

  %default_values=@$DEFAULT_ARGS_ref;
  @arg_names=();
  foreach ( 0..$#$DEFAULT_ARGS_ref ) {
    push(@arg_names,$DEFAULT_ARGS_ref->[$_]) if ($_ % 2) == 0;
  }

  ### hash that will be returned
  my %returnARGS;

  ####################
  ### Check if the last argument passed to our calling function is
  ### a hash ref.  If so use the hash values for arguments unless 
  ### the function was expecting a hash ref as the last argument.
  ### Match passed keys to expected keys case-insensitively.
  ####################
  # is the last argument passed a hash ref?
  if (ref($PASSED_ARGS_ref->[$#$PASSED_ARGS_ref]) eq "HASH") {
    # is the corresponding expected parameter defaulting to a hash ref?
    if ( ref($DEFAULT_ARGS_ref->[($#$PASSED_ARGS_ref * 2) + 1]) ne "HASH" ) {
      my %arg_hash = %{pop @$PASSED_ARGS_ref};
      foreach $arg_name (keys %arg_hash) {
        foreach $expect_name (keys %default_values) {
          if ($arg_name =~ /^$expect_name$/i) {
            $returnARGS{$expect_name} = $arg_hash{$arg_name};
          }
        }
      }
    }
  }

  ### for the remaining arguments of the calling function fill in
  ### with a default value if they are not set, or overwrite with
  ### the ordered list arguments of the calling function
  foreach (@arg_names) {
    if ( @$PASSED_ARGS_ref ) {
      $returnARGS{$_} = shift(@$PASSED_ARGS_ref);
    } elsif ( !defined($returnARGS{$_}) ) {
      $returnARGS{$_} = $default_values{$_};
    }
  }

  ### all done
  return %returnARGS;
}

1;
