package List::Part;

#Prototypes
BEGIN { require 5.002 }

use Carp qw(croak);

use Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw( parta );
@EXPORT = qw( part );

$VERSION = '0.03';

use strict;
use warnings;

sub part(&@) {
    my $code=shift;
    my @ret;
    
    for(@_) {
        my $i=$code->($_);
        next unless defined $i;
        push @{$ret[$i]}, $_;
    }
    
    return @ret;
}

sub parta($@) {
    my $ary=shift;
    
    unshift @_, sub {
        for my $i(0..$#$ary) {
            return $i if _matches($ary->[$i], $_);
        }
        return undef;
    };
    
    goto &part;
}

sub _matches {
    my($thing, $value)=@_;
    
    if(ref $thing) {
        if(ref $thing eq 'ARRAY') {
            for(@$thing) {
                return 1 if _matches($_, $value);
            }
        }
        elsif(ref $thing eq 'HASH') {
            return 1 if $thing->{$value};            
        }
        elsif(ref $thing eq 'CODE') {
            return 1 if $thing->($value);
        }
        elsif(ref $thing eq 'Regexp') {
            return 1 if $value =~ $thing;
        }
        else {
            return 1 if $thing eq $value;
        }
    }
    else {
        return 1 if $thing eq $value;
    }
    
    return 0;
}

1;

__END__

=head1 NAME

List::Part - Partition one array into several

=head1 SYNOPSIS

    use List::Part;
    ($good, $bad)=part { !/substring/ } @array; #store arrayrefs into $good and $bad
    (*good, *bad)=part { !/substring/ } @array; #store into @good and @bad

=head1 ABSTRACT

List::Part implements the C<part> function, allowing one array to be "partitioned" into 
several based on the results of a code reference.

=head1 DESCRIPTION

There are many applications in which the items of a list need to be categorized.  For 
example, let's say you want to categorize lines in a log file:

    my($success, $failure)=part { /^ERR/ } <LOG>;

Or, suppose you have a list of employees, and you need to determine their fate:

    my($lay_off, $give_raise, $keep)=part {
          $_->is_talented  ? 0 
        : $_->is_executive ? 1 
        :                    2
    } @employees;

Actually, the second one is better suited to C<part>'s alternate form, C<parta>:

    my($lay_off, $give_raise, $keep)=parta
        [ sub { $_->talented }, sub { $_->is_executive }, qr// ] => 
        @employees;

Or maybe you just want yet another way to write the traditional Perl signoff:

    perl -MList::Part -e"print map{@$_}part{$i++%5}split'','JAercunrlkso  ettPHr hea,'"

List::Part can help you do those sorts of things.

=head2 Functions

=head3 C<part>

C<part> takes a code reference and an array and returns a list of array references.  The 
coderef should examine the value in either C<$_> or its argument list and return a 
(zero-based) index indicating which array the value should go into.  Built-in Perl 
functions that emit booleans, such as regular-expression matches or file operators, are 
also suitable for this--but note that the I<second> array is the one that receives true 
values, I<not> the first.  Returning C<undef> will cause C<part> to throw away the 
value, so that none of the arrays will receive it.

The function is prototyped C<(&@)>, which means that, like the built-in C<map> and C<grep>, 
you can pass it a bare block without using C<sub>.

Tip: As mentioned before, this function returns a list of array references; if you want the 
results to be assigned to (global) arrays, then assign to typeglobs:

    (*a, *b, *c)=part { ... } @list;

=head3 C<parta>

C<parta> is a wrapper around C<part> which can reduce the amount of code under certain 
circumstances.  Instead of taking a code reference, C<parta> takes an array reference 
containing strings or certain types of references; the index of the first item an incoming 
value "matches" is the index of the list it ends up in.  For example:

    ($a, $b, $c)=part [ qr/a/, qr/b/, qr/c/ ] => qw(a b c aa ab bc);
    # $a=[ qw(a aa ab) ], $b=[ qw(b bc) ], $c=[ qw(c) ]

The match rules are fairly sophistocated, and vary based on the type of item in the 
arrayref:

=over 4

=item * B<Strings (and other plain scalars)> are compared using C<eq>.

=item * B<Array references> match if any of their elements matches the value.

=item * B<Hash references> match if their associated value in the hash, i.e. 
C<< $hashref->{$value} >>, is true.

=item * B<Code references> match if, when invoked on the item, they return true.

=item * B<Regexen> (such as those produced by C<qr//>) match if the item matches
them.

=item * B<Other references> are compared using C<eq>.

=back 4

C<parta> carries the prototype C<($@)>.

Tip: If you want the results to include a "rejects" array, add an empty regex (C<qr//>) to 
the end of the arrayref.

=head2 Exporting

C<part> is exported by default; C<parta> can be exported specifically.

=head1 BUGS and ENHANCEMENTS

There are no known bugs, and since the code for this module is fairly simple, I don't 
expect there will be many.

Bug reports and enhancement requests are welcome, but I'm far more likely to act on them if 
they're accompanied by a patch fixing/implementing them.  Also, if you get this to work on 
older versions of Perl without changing any functionality, I will happily apply your patch.
Send reports/requests to <brent@brentdax.com>.

=head1 SEE ALSO

The Perl 6 design, which includes a more powerful version of C<part>.

=head1 AUTHOR

Brent Dax <brent@brentdax.com>

=head1 COPYRIGHT

Copyright (C) 2003 Brent Dax.  All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
