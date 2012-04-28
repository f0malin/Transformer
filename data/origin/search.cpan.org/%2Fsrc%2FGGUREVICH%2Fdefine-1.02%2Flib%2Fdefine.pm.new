package define;

use 5.008004;
use strict;
use warnings;

our $VERSION = '1.02';

my %AllPkgs;
my %DefPkgs;
my %Vals;

my %Forbidden = map { $_ => 1 } qw{ 
  BEGIN INIT CHECK END DESTROY AUTOLOAD 
  STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG 
};

sub import {
  my $class = shift;
  my $pkg = (caller)[0];
  if( @_ ) {
    if( ref $_[0] eq 'HASH' ) {
      while( my( $name, $val ) = each %{$_[0]} ) {
        do_import( $pkg, $name, $val );
      }
    }
    else {
      do_import( $pkg, @_ );
    }
  }
  else {
    require Carp;
    Carp::croak "Must call 'use define' with parameters";
  }
}

sub unimport {
  my $class = shift;
  my $pkg = (caller)[0];
  if( @_ ) {
    check_name( my $name = shift );
    $DefPkgs{$name}{$pkg} = 1;
    if( $Vals{$name} ) {
      makedef( $pkg, $name, @{$Vals{$name}} );
    }
    else {
      makedef( $pkg, $name );
    }
  }
  else {
    # export all Declared to pkg
    $AllPkgs{$pkg} = 1;
    while( my( $name, $val ) = each %Vals ) {
      # warn "Defining ALL $pkg:$name:$val";
      makedef( $pkg, $name, @$val );
    }
  }
}

sub check_name {
  my $name = shift;
  if( $name =~ /^__/ 
      or $name !~ /^_?[^\W_0-9]\w*\z/ 
      or $Forbidden{$name} ) {
    require Carp;
    Carp::croak "Define name '$name' is invalid";
  }
}

sub do_import {
  my( $pkg, $name, @vals ) = @_;
  check_name( $name );
  $DefPkgs{$name}{$pkg} = 1;
  $Vals{$name} = [ @vals ];
  my %pkgs = ( $pkg => 1, %AllPkgs, %{$DefPkgs{$name}} );
  for (keys %pkgs) {
    makedef( $_, $name, @vals );
  }
}

sub makedef {
  my ($pkg, $name, @Vals) = @_;
  my $subname = "${pkg}::$name";

  no strict 'refs';

  if (defined *{$subname}{CODE}) {
    require Carp;
    Carp::carp "Global constant $subname redefined";
  }

  if (@Vals > 1) {
    *$subname = sub () { @Vals };
  }
  elsif (@Vals == 1) {
    my $val = $Vals[0];
    *$subname = sub () { $val };
  }
  else {
    *$subname = sub () { };
  }
}
  
1;

__END__

=head1 NAME

define - Perl pragma to declare global constants

=head1 SYNOPSIS

    #--- in package/file main ---#
    package main;
    
    # the most frequenly used application of this pragma
    use define DEBUG => 0;
    
    # define a constant list
    use define DWARVES => qw(happy sneezy grumpy);
    
    # define several at a time via a hashref list, like constant.pm
    use define {
      FOO => 1,
      BAR => 2,
      BAZ => 3,
    };

    use Some::Module;
    use My::Module;
    
    #--- in package/file Some::Module ---#
    package Some::Module
    no define DEBUG =>;
    no define DWARVES =>;

    # define a master object that any package can import
    sub new { ... }
    use define OBJECT => __PACKAGE__->new;

    # if DEBUG is false, the following statement isn't even compiled
    warn "debugging stuff here" if DEBUG;
    
    my $title = "Snow white and the " . scalar DWARVES . " dwarves";

    #--- in package/file My::Module ---#
    package My::Module
    no define;

    warn "I prefer these dwarves: " join " ", DWARVES if DEBUG;
    OBJECT->method(DWARVES);

=head1 DESCRIPTION

Use this pragma to define global constants.

=head1 USAGE

=head2 Defining constants

Global constants are defined through the same calling conventions 
as C<constant.pm>:

  use define FOO => 3;
  use define BAR => ( 1, 2, 3 );
  use define { 
    BAZ => 'dogs',
    QUX => 'cats',
  };

=head2 Importing constants by name

To use a global constant, you import it into your package as follows:

  no define FOO =>;

If FOO has been defined, it gets set to its defined value, otherwise it is set
to undef. Note that the reason for the '=>' operator here is to parse FOO as 
a string literal rather than a bareword (you could also do C<no define 'FOO'>).

=head2 Importing constants willy-nilly

To import ALL defined constants into your package, you can do the following:

  no define;

This is quick, but messy, as you can't predict what symbols may clash with
those in your package's namespace.

=head1 NOTES

See L<constant/"constant.pm">. Most of the same caveats apply here.

Your code should be arranged so that any C<no define> statements are executed 
after the C<use define> statement for a given symbol. If the order is reversed,
a warning will be emitted.

As a rule, modules shouldn't be defining global constants; they should import
constants defined by the main body of your program.

If a module does define a global constant (eg. a master object), the module 
should be use'd before any other modules (or lines of code) that refer to the
constant.

If you <use define> the same symbol more than once, a warning will be emitted.

=head1 AUTHOR

  Gary Gurevich (garygurevich at gmail)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Gary Gurevich

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 SEE ALSO

constant(3), perl(1).

=cut