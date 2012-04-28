#!/usr/bin/perl
use strict;
use warnings;

# This test is supposed to make sure that
# the /tmp/par-$USER/temp-$$ directories get cleaned up when
# in CLEAN mode.

use File::Temp ();
use Test::More tests => 5;

BEGIN {
  $ENV{PAR_TMPDIR} = File::Temp::tempdir(TMPDIR => 1, CLEANUP => 1);
  $ENV{PAR_CLEAN} = 1;
  delete $ENV{PAR_TEMP};
}

ok(!defined $ENV{PAR_TEMP}, "No PAR_TEMP to start with");

require PAR;
PAR->import();

ok(1, "Loaded PAR");

ok(defined $ENV{PAR_TEMP}, "Loading PAR defined PAR_TEMP");
ok(-d $ENV{PAR_TEMP}, "Loading PAR created the PAR_TEMP directory");

my $partemp = $ENV{PAR_TEMP};

END {
  ok(not -d $partemp);
}


__END__

