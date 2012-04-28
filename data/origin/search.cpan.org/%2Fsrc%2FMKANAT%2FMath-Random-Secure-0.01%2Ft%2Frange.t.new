#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;
use Math::Random::Secure qw(rand irand);
use Data::Dumper;
use List::MoreUtils qw(all);

sub check_range {
    my ($numbers, $type, $limit) = @_;
    $limit ||= 10;
    my $all_less = all { $_ < $limit } @$numbers;
    ok($all_less, "all $type less than $limit")
        or diag Dumper($numbers);
    my $all_more = all { $_ >= 0 } @$numbers;
    ok($all_more, "all $type greater or equal to 0")
        or diag Dumper($numbers);
}

my @numbers = map { rand(10) } (1..100);
check_range(\@numbers, 'floats');

my @ints = map { irand(10) } (1..100);
check_range(\@ints, 'integers');

my @made_ints = map { int(rand(10)) } (1..100);
check_range(\@made_ints, 'made integers');

my @zero_to_one = map { rand() } (1..100);
check_range(\@zero_to_one, 'zero to one', 1);

my @all_ints = map { irand() } (1..1000);
check_range(\@all_ints, 'full range integers', 2**32);

my @floats_zero = map { rand(0) } (1..100);
check_range(\@floats_zero, 'zero floats', 1);

my @ints_zero = map { irand(0) } (1..100);
check_range(\@ints_zero, 'zero ints', 1);

my @ints_one = map { irand(1) } (1..100);
check_range(\@ints_one, 'one ints', 1);
