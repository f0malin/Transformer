#!perl -w

use Test::More;

use IPC::Run3;
use strict;

my ( $in, $out, $err ) = @_;

sub leaky
{
    my ($what) = @_;

    my $before_fd = IPC::Run3::_max_fd();
    my $desc = join ",", map {
	defined $_
	    ? ref $_
		? ( $_ == \undef )
		    ? "\\undef"
		    : ref $_
		: "'$_'"
	    : 'undef';
    } @$what;

    run3 [$^X, '-e1' ], @$what;

    my $after_fd = IPC::Run3::_max_fd();

    # on a sane system we'd expect == below, 
    # but apparently Darwin 7.2 is stranger than fiction
    ok($after_fd <= $before_fd, "run3 [...],$desc");
}

my @tests = (
    [],
    [ \undef               ],
    [ \$in                 ],
    [ $0                   ],
    [ undef,  \$out        ],
    [ undef,  undef, \$err ],
    [ undef,  \$out, \$err ],
    [ \undef, \$out, \$err ],
    [ \$in,   \$out, \$err ],
    [ $0,     \$out, \$err ],
);

plan tests => 1+@tests;

## Force run3() to open some temp files.
run3 [$^X, '-e1' ], \$in, \$out, \$err;
ok(1, "open some temp files");

leaky($_) for @tests;
