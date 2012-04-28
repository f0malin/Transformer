package Perl6::Parameters;

use 5.006;
use strict;
use warnings;
use Switch 'Perl6';		#given/when

our $VERSION = '0.03';

use Filter::Simple;

sub separate($);
sub makeproto(\@\@);
sub makepopstate(\@\@);

FILTER_ONLY code => sub {
	while(/(sub\s+([\w:]+)\s*\(([^)]*\w.*?)\)\s*\{)/) {
		my($oldsubstate, $subname, $paramlist)=($1, $2, $3);
		my($substate);
		
		die "'is rw' is not implemented but is used in subroutine $subname" if($oldsubstate =~ /is rw/);
		
		#build the new sub statement
		do {
			my($popstate, $proto);
			
			do {
				#separate the parameter list into 3 arrays
				my(@ret)=separate($paramlist);
				my(@seps)=@{$ret[0]}; my(@params)=@{$ret[1]}; my(@names)=@{$ret[2]};

				#form the line-noise prototype
				($proto, my(@symbols))=makeproto(@params, @seps);
				
				#form the population statements
				$popstate=makepopstate(@names, @symbols);
			};

			#now assemble the new sub statement
			$substate="sub $subname ($proto) {\n\t$popstate"; warn "subname" unless defined $subname; warn "proto" unless defined $proto; warn "popstate" unless defined $popstate;
		};
		#$substate: DONE--contains the new sub statement

		#replace the old sub statement with the new one
		do {
			s/\Q$oldsubstate/$substate/;
		};
	}
	
	if(@_) {
		print STDERR $_ if($_[0] eq '-debug');
	}
};

sub separate($) {
	my($paramlist, @seps, @names, @params)=shift;
	my(@things);
	
	#split the param list on separators--but keep the separators around
	@things=split /([,;])/, $paramlist;

	#separate the things into separators and parameters
	for(0..$#things) {
		if($_ % 2) {
			push @seps, $things[$_];
		}
		else {
			push @params, $things[$_];
		}
	}

	#form the names array
	push @names, (/([\$\@\%]\w+)$/)[0] for @params;
	
	return \@seps, \@params, \@names;
}

sub makeproto(\@\@) {
	my($params, $seps)=@_;
	my(@symbols, $proto);
	
	#first, we convert each parameter to the appropriate symbol
	for(@$params) {
		push @symbols, tosymbol($_);
	}
	
	#then we get rid of commas since they don't appear in line-noise prototypes
	@$seps=map {$_ eq ',' ? "" : $_} @$seps;
	push @$seps, '';	#avoid warning
	
	#build the line-noise prototype
	$proto.="$symbols[$_]$seps->[$_]" for(0..$#symbols);
	
	return $proto, @symbols;
}

sub makepopstate(\@\@) {
	my(@names)=@{shift()};
	my(@symbols)=@{shift()};
	my($popstate);
		
	for(0..$#names) {
		given($symbols[$_]) {
			when '\@' {
				if($names[$_] =~ /\@/) {
					#literal array--use it
					$popstate .= "my($names[$_])=\@{shift()};\n";
				}
				else {
					#array ref--just like a normal one
					$popstate .= "my($names[$_])=shift;\n";
				}
			}
		
			when '\%' {
				if($names[$_] =~ m'%') {
					#literal hash--use it
					$popstate .= "my($names[$_])=\%{shift()};\n";
				}
				else {
					#hash ref--just like a normal one
					$popstate .= "my($names[$_])=shift;\n";
				}
			}
		
			when '@' {
				if($names[$_] ne '@_') {
					$popstate .= "my($names[$_])=(\@_);\n";
				}
			}
		
			when '%' {
				if($names[$_] eq '%_') {
					$popstate .= '(%_)=(@_);'
				}
				else {
					$popstate .= "my($names[$_])=(\@_);\n"
				}
			}
		
			$popstate .= "my($names[$_])=shift;\n";
		}
	}

	return $popstate;
}



sub tosymbol {
	my $term=shift;
	$term =~ s/^\s+|\s+$//g;	#strip whitespace

	given($term) {
		when /^REF/    { return $^V gt 5.8.0 ? '\\[$@%]' : '$' }
		when /^GLOB/   { return '\*' }
		when /^CODE/   { return '&'  }
		when /^HASH/   { return '\%' }
		when /^ARRAY/  { return '\@' }
		when /^SCALAR/ { return '\$' }
		when /^\*\@/   { return '@'  }
		when /^\*\%/   { return '%'  }
		when /^\@/     { return '\@' }
		when /^\%/     { return '\%' }
		               { return '$'  }
	}
}

1;

=head1 NAME

Perl6::Parameters – Perl 6-style prototypes with named parameters

=head1 SYNOPSIS

	use Perl6::Parameters;

	sub mysub($foo, ARRAY $bar, *%rest) {
		...
	}

=head1 DETAILS

Perl6::Parameters is a Perl module which simulates Perl 6's named parameters.  (When I
talk about "named parameters" I mean something like the parameters you're used to from
C, Java and many other languages--not pass-a-hash-with-the-parameters-in-it things.)

Like most other programming languages, Perl 6 will support subroutines with
pre-declared variables the parameters are put into.  (Using this will be optional,
however.)  This goes far beyond the "line-noise prototypes" available in Perl 5, which
only allow you to control context and automatically take references to some
parameters--lines like C<my($first, $second)=(@_)> will no longer be necessary.

Although Perl 6 will have this, Perl 5 doesn't; this module makes it so that Perl 5
does.  It uses some other Perl 6-isms too, notably the names for builtin types and the
unary-asterisk notation for flattening a list.

=head2 Crafting Parameter Lists

Crafting parameter lists is simple; just declare your subroutine and put the parameters
separated by commas or semicolons, in parenthesis.  (Using a semicolon signifies that
all remaining parameters are optional; this may not be available this way in Perl 6,
but I'm assuming it is until I hear otherwise.)

Most parameters are just variable names like C<$foo>; however, more sophisticated
behavior is possible.  There are three ways to achieve this.

The first way is by specifying a type for the variable.  Certain types make the actual
parameters turn into references to themselves:

=over 4

=item *
C<ARRAY $foo>

This turns an array into a reference to itself and stores the reference into C<$foo>.

=item *
C<HASH $foo>

This turns a hash into a reference to itself and stores the reference into C<$foo>.

=item *
C<CODE $foo>

This turns a subroutine into a reference to itself and stores the reference into
C<$foo>.

=item *
C<SCALAR $foo>

This turns a scalar into a reference to itself and stores the reference into C<$foo>.

=item *
C<GLOB $foo>

This turns a typeglob into a reference to itself and stores the reference into C<$foo>.  Typeglobs will be going away in Perl 6; 
this type exists in this module so that it's useful for general use in Perl 5.

=item *
C<REF $foo>

This turns any parameter into a reference to itself and stores it into C<$foo>.

This only works in Perl 5.8.  Otherwise, it's treated the same as any other
unrecognized type name.

=item *
C<AnythingElse $foo>

This has no effect in this module; it's treated as though you'd typed C<$foo> without
the C<AnythingElse>.

=back

For example, if a subroutine had the parameters C<($foo, HASH $bar, CODE $baz)> and was
called with C<($scalar, %hash, &mysub)> the subroutine would get the contents of 
C<$scalar>, a reference to C<%hash> and a reference to C<&mysub>.

The second way is by supplying an actual array or hash as a parameter name.  This
requires an array or hash to be passed in for that parameter; it preserves the length
of the array or hash.

The final way is only available for the last parameter: if an array or hash is prefixed
with an asterisk, that array or hash will be filled with any additional parameters.

=head1 CAVEATS

=over 4

=item *

In Perl 6, parameters will be passed by constant reference; in this module parameters
are passed by value.

=item *

In Perl 6, putting an C<is rw> at the end of a parameter will make it read-write;
trying to use C<is rw> with this module will cause an error.

=item *

C<@_> and C<%_> may only be used for the last parameter, and then only when prefixed by
an asterisk; any other use causes undefined behavior.

=item *

In Perl 6 a definition like C<HASH $foo> will take either a literal hash (with a C<%>
sign in front of it) or a reference to a hash; this module requires a C<%> sign.
(Similar limitations apply for arrays.)

=back

=head1 BUGS

None known--but if you find any, send them to <bug-Perl6-Parameters@rt.cpan.org> and
CC <brentdax@cpan.org>.

=head1 AUTHOR

Brent Dax <brentdax1@earthlink.net>

=head1 COPYRIGHT

Copyright (C) 2001 Brent Dax.

This module is free software and may be used, redistributed and modified under the same
terms as Perl itself.

=cut