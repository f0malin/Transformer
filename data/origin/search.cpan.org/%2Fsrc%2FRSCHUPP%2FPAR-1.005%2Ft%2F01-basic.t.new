#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
use File::Spec;
use File::Path;
use File::Temp ();

BEGIN {
  $ENV{PAR_TMPDIR} = File::Temp::tempdir(TMPDIR => 1, CLEANUP => 1);
  $ENV{PAR_CLEAN} = 1;
}

ok(
    `"$^X" -Mblib -MPAR -It/hello -MHello -e Hello::hello`,
    "Hello, world!\n",
);

ok(
    `"$^X" -Mblib -MPAR t/hello.par hello.pl`,
    "Hello, world!\nGoodbye, world!\n",
);

ok(
    `"$^X" -Mblib -MPAR t/hello.par nostrict.pl`,
    "No Strict!\n",
);

ok(
    `"$^X" -Mblib -MPAR t/hello.par data.pl`,
    "Data section\nData reflection\n",
);

require PAR;
PAR->import('t/hello.par');

ok(
    PAR::read_file('script/hello.pl'),
    qr/Hello::hello/,
);

ok( my $zip = PAR::par_handle('t/hello.par') );
ok( my $member = $zip->memberNamed('lib/Hello.pm') );
ok(
    $member->contents,
    qr/package Hello/,
);

__END__
