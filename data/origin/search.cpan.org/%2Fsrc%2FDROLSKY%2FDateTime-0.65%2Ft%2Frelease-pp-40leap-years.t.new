use Test::More;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        plan skip_all => 'these tests are for testing by the release';
    }

    $ENV{PERL_DATETIME_PP} = 1;
}

use strict;
use warnings;

use Test::More;

use DateTime;

for my $y ( 0, 400, 2000, 2004 ) {
    ok( DateTime->_is_leap_year($y), "$y is a leap year" );
}

for my $y ( 1, 100, 1900, 2133 ) {
    ok( !DateTime->_is_leap_year($y), "$y is not a leap year" );
}

done_testing();

