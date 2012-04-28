# $Id: autosearch.t,v 1.9 2008/07/16 00:41:37 Martin Exp $

use ExtUtils::testlib;
use File::Spec::Functions;
use Test::File;
use Test::More qw(no_plan);

use strict;

my $sProg = catfile('blib', 'script', 'AutoSearch');
my $iWIN32 = ($^O =~ m!win32!i);

file_exists_ok($sProg, "$sProg exists");
SKIP:
  {
  skip 'Can not check "executable" file flag on Win32', 1 if $iWIN32;
  file_executable_ok($sProg, "$sProg is executable");
  } # end of SKIP block
pass();
# print STDERR "\n";
diag(`$sProg -V`);
pass();
exit 0;

__END__

