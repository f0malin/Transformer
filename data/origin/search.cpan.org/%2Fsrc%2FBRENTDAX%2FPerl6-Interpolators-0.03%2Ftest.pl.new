use Test;

BEGIN { plan tests => 9 };

use Perl6::Interpolators;

ok(1);											# If we made it this far, we're ok.

my($obj, $foo, @foo)=(new main, 0..9);

sub new { bless []; }
sub Foo { wantarray ? @foo : $foo }


ok("$(Foo)",			"$foo");				#test scalar interpolation
ok("@(Foo)",			"@foo");				#test list interpolation
ok("$($obj->Foo)",		"$foo");				#test method interpolation
ok($(Foo),				$foo);					#test scalar context cast
ok(@(Foo)[2],			$foo[2]);				#test list context cast
ok("@(Foo)[7]",			$foo[7]);				#item selection from an array

ok("$(Foo(')'))", "$foo");						#funky use of parenthesis

no Perl6::Interpolators;
eval(q{ok("$(Foo)",		$( . 'Foo)')});			#make sure no works right
print "not ok 9" if $@;