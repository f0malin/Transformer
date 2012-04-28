use Test;
use IPC::Run3;
use strict;

my ( $in, $out, $err ) = @_;

my @tests = (
sub {
    ## Force run3() to open some temp files.
    run3 [$^X, '-e1' ], \my ( $in, $out, $err );
    ok 1;
},

map {
    my @what = @$_;

    sub {
        my $before_fd = IPC::Run3::_max_fd();
        my $desc = join ",", map {
            defined $_
                ? ref $_
                    ? ( $_ == \undef )
                        ? "\\undef"
                        : ref $_
                    : "'$_'"
                : 'undef';
        } @what;

        run3 [$^X, '-e1' ], @what;

        my $after_fd = IPC::Run3::_max_fd();

        ok $after_fd, $before_fd, $desc;
    },
} (
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
),
);

plan tests => 0+@tests;

$_->() for @tests;
