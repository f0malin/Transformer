#!/usr/bin/perl -w -Ilib
use strict;
use Payroll::AU::PAYG;

my $payroll = Payroll::AU::PAYG->new;
my $result = $payroll->calculate(GrossEarnings => 1000);
print "I'm paying \$$result->{tax} this fortnight\n";
