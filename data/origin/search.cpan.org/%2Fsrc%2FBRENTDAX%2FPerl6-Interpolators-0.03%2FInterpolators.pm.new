package Perl6::Interpolators;

use 5.6.0;
use strict;
use warnings;

our $VERSION = '0.03';

use Text::Balanced qw(extract_codeblock);

use Filter::Simple sub {
    my($inside_stuff, $t, $pos);
	
    while(($pos=index($_, '$(')) != -1) {
        $t=substr($_, $pos);
        $inside_stuff=extract_codeblock($t, '()', qr/\$/);

        s<\$\Q$inside_stuff\E><\${\\scalar$inside_stuff}>
    }
	
    ($inside_stuff, $t, $pos)=(undef, undef, undef);

    while(($pos=index($_, '@(')) != -1) {
        $t=substr($_, $pos);
        $inside_stuff=extract_codeblock($t, '()', qr/\@/);

        s<\@\Q$inside_stuff\E><\@{[$inside_stuff]}>
    }
};

1;

__END__

=head1 NAME

Perl6::Interpolators - Use Perl 6 function-interpolation syntax

=head1 SYNOPSIS

	use Perl6::Interpolators;
	sub Foo { 1 }
	sub Bar { 1..5 }
	sub Baz { @_ }
	sub Context { wantarray ? 'list' : 'scalar' }

	print "Foo: $(Foo)\n";			#prints Foo: 1
	print "Bar: @(Bar)\n";			#prints Bar: 1 2 3 4 5

	print "Baz: $(Baz('a', 'b'))";		#prints Baz: b
	print "Baz: @(Baz('a', 'b'))";		#prints Baz: a b

	print "$(Context)";				#prints scalar
	print "@(Context)";				#prints list

=head1 DESCRIPTION

Perl6::Interpolate allows you to interpolate function calls into
strings. Because of Perl's contexts, Perl6::Interpolate requires a sigil
(a funny character--$ or @ in this case) to tell the function being
called which context to use; thus, the syntax is C<$(>I<call>C<)> for
scalar context or C<@(>I<call>C<)> for list context. (This syntax is
expected to be used for the same thing in Perl 6, too.)

Perl6::Interpolate will work on both fuction and method calls. It will
work on parenthesized calls. It even works outside quotes, where it can
be used to control context. (This may be the only way to get a list
context in some cases, for example.)

=head1 BUGS

=over 4

=item *

Using this module precludes use of $(.  However, you can temporarily disable the module while you munge with $(:

	no Perl6::Interpolators;
	#now mess with $(
	use Perl6::Interpolators

=item *

Currently this module will make changes inside single-quoted strings.  It won't interpolate a call--it'll just look funny.

=back

=head1 AUTHOR

Brent Dax E<lt>brentdax1@earthlink.netE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Brent Dax.  All Rights Reserved.

This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.

=cut