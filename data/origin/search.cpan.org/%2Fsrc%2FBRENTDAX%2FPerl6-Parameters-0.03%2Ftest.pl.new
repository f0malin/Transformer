use Perl6::Parameters;
use strict;
use warnings;

use Test;
BEGIN { plan tests => 5 };

ok(1); # If we made it this far, we're ok.

sub test2($foo)         { $foo;				}
sub test3($foo, $bar)   { "$foo$bar";		}
sub test4(*@stuff)      { "@stuff";			}
sub test5(@stuff, $foo) { "@stuff$foo";		}
sub test6(ARRAY $stuff) { "$stuff";			}


my($FOO, $BAR, @STUFF)=qw(foo bar stuff0 stuff1);

ok(test2($FOO),				"$FOO"			);
ok(test3($FOO, $BAR),		"$FOO$BAR"		);
ok(test4(@STUFF),			"@STUFF"		);
ok(test5(@STUFF, $FOO),		"@STUFF$FOO"	);
ok(test6(@STUFF),			\@STUFF			);