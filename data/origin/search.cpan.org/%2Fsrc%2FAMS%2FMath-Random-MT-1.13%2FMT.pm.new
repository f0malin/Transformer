package Math::Random::MT;

use strict;
use Carp;
use DynaLoader;
use Time::HiRes qw(gettimeofday); # standard in Perl >= 5.8
use vars qw( @ISA $VERSION );

my $gen = undef;
@ISA = qw( DynaLoader );
$VERSION = '1.13';

bootstrap Math::Random::MT $VERSION;

sub new
{
    my ($class, @seeds) = @_;

    my $self = Math::Random::MT::init();
    $self->set_seed(@seeds);

    return $self;
}

sub set_seed
{
    my ($self, @seeds) = @_;
    @seeds > 1 ? $self->setup_array(@seeds) :
                 $self->init_seed($seeds[0] || _rand_seed());
    return $self->get_seed;
}

sub srand
{
    my (@seeds) = @_;
    $gen = Math::Random::MT->new(@seeds);
    return $gen->get_seed;
}

sub rand
{
    my ($self, $N) = @_;

    unless (ref $self) {
        $N = $self;
        Math::Random::MT::srand() unless defined $gen;
        $self = $gen;
    }

    return ($N || 1) * $self->genrand();
}

# Generate a random seed using the built-in PRNG.

sub _rand_seed {
    my ($self) = @_;

    # Seed rand with the same gettimeofday-based formula that is
    # used in Perl, and return an integer between 0 and 2**32-1.

    my ($s, $u) = gettimeofday;
    CORE::srand(1000003*$s+3*$u);
    return int(CORE::rand(2**32));
}

sub import
{
    no strict 'refs';
    my $pkg = caller;
    foreach my $sym (@_) {
        if ($sym eq "srand" || $sym eq "rand") {
            *{"${pkg}::$sym"} = \&$sym;
        }
    }
}

1;

__END__

=head1 NAME

Math::Random::MT - The Mersenne Twister PRNG

=head1 SYNOPSIS

  ## Object-oriented interface:
  use Math::Random::MT;
  $gen = Math::Random::MT->new()        # or...
  $gen = Math::Random::MT->new($seed);  # or...
  $gen = Math::Random::MT->new(@seeds);
  $seed = $gen->get_seed();             # seed used to generate the random numbers
  $rand = $gen->rand(42);               # random number in the interval [0, 42)
  $dice = int($gen->rand(6)+1);         # random integer between 1 and 6
  $coin = $gen->rand() < 0.5 ?          # flip a coin
    "heads" : "tails"

  ## Function-oriented interface:
  use Math::Random::MT qw(srand rand);
  # now use srand() and rand() as you usually do in Perl

=head1 DESCRIPTION

The Mersenne Twister is a pseudorandom number generator developed by
Makoto Matsumoto and Takuji Nishimura. It is described in their paper at
<URL:http://www.math.keio.ac.jp/~nisimura/random/doc/mt.ps>. This algorithm
has a very uniform distribution and is good for modelling purposes but do not
use it for cryptography.

This module implements two interfaces:

=head2 Object-oriented interface

=over

=item new()

Creates a new generator that is automatically seeded based on gettimeofday.

=item new($seed)

Creates a new generator seeded with an unsigned 32-bit integer.

=item new(@seeds)

Creates a new generator seeded with an array of (up to 624) unsigned
32-bit integers.

=item set_seed()

Seeds the generator. It takes the same arguments as I<new()>.

=item get_seed()

Retrieves the value of the seed used.

=item rand($num)

Behaves exactly like Perl's builtin rand(), returning a number uniformly
distributed in [0, $num) ($num defaults to 1).

=back

=head2 Function-oriented interface

=over

=item rand($num)

Behaves exactly like Perl's builtin rand(), returning a number uniformly
distributed in [0, $num) ($num defaults to 1).

=item srand($seed)

Behaves just like Perl's builtin srand(). As in Perl >= 5.14, the seed is
returned. If you use this interface, it is strongly recommended that you
call I<srand()> explicitly, rather than relying on I<rand()> to call it the
first time it is used.

=back

=head1 SEE ALSO

<URL:http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html>

Data::Entropy

=head1 ACKNOWLEDGEMENTS

=over 4

=item Sean M. Burke

For giving me the idea to write this module.

=item Philip Newton

For several useful patches.

=item Florent Angly

For implementing seed generation and retrieval.

=back

=head1 AUTHOR

Abhijit Menon-Sen <ams@toroid.org>

Copyright 2001 Abhijit Menon-Sen. All rights reserved.

Based on the C implementation of MT19937
Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura

This software is distributed under a (three-clause) BSD-style license.
See the LICENSE file in the distribution for details.
