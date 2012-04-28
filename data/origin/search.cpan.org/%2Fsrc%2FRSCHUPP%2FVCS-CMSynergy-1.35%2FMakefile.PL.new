#!/usr/bin/perl -w

# Copyright (c) 2001-2010 argumentum GmbH, 
# See COPYRIGHT section in VCS/CMSynergy.pod usage and distribution rights.

# $Revision: 381 $

use inc::Module::Install;
use Config;
use strict;

# --- Check that Synergy CLI is installed

sub nay { warn(@_); exit(0); }
# NOTE: Don't die if the following checks fail,
# just exit(0) without producing a Makefile -
# the automated CPAN tests will interpret this as an indicator that
# a prerequisite of this module is missing and will generate 
# an NA report instead of FAIL.

nay qq{
  The CCM_HOME environment variable must be set
  to the path of the Synergy installation directory.
  See the README file for more information.
  ABORTED!
} unless $ENV{CCM_HOME};

my $ccm_exe = MY->catfile(
    $ENV{CCM_HOME}, "bin", "ccm$Config{_exe}");
nay qq{  
  The value ($ENV{CCM_HOME})
  of the CCM_HOME environment variable is not valid.
  It must be set to the path of the Synergy installation directory.
  See the README file for more information.
  ABORTED!
} unless -x $ccm_exe || ($^O eq 'cygwin' && -e $ccm_exe);
# NOTE: -x $ccm_exe fails on cygwin

my $ccm_version = qx("$ccm_exe" version);
nay qq{  
  The Synergy CLI program ($ccm_exe)
  doesn't appear to work on this machine. 
  See the README file for more information.
  ABORTED!
} unless $? == 0;

nay qq{  
  Failed to recognize the output of
  "$ccm_exe version" -
  perhaps this Synergy version is too old or too new.
  ABORTED!
} unless $ccm_version =~ m{(CM Synergy|SYNERGY/CM|Telelogic Synergy|IBM Rational Synergy)\s+Version\s+(\d+\.\d+)}i;
print "Detected $1 version $2\n";

warn qq{
  Please install module Scalar::Util and make sure it implements weaken().
  Without weaken(), a Synergy session might not be stopped as soon
  as the corresponding VCS::CMSynergy object goes out of scope
  (however, all sessions will be stopped when the script exits).
  Cf. "Why is Scalar::Util recommended?" in the POD for 
  VCS::CMSynergy::Object for details.
} unless (eval "use Scalar::Util qw(weaken); 1");


# --- Define metadata

name		'VCS-CMSynergy';
author		'Roderich Schupp <schupp@argumentum.de>';
license		'perl';
abstract_from	'lib/VCS/CMSynergy.pod';
version_from	'lib/VCS/CMSynergy.pm';

# --- Dependencies

requires	'perl'			=> '5.006';
requires	'File::Spec'		=> 0;
requires	'File::Temp'		=> 0;
requires	'IPC::Run3'		=> '0.030';
requires	'Time::HiRes'		=> 0;
requires	'Class::Accessor::Fast' => 0;
requires	'List::Util'		=> '1.09';
requires	'Scalar::Util'		=> '1.09';
requires	'Filesys::CygwinPaths'	=> 0 if $^O eq 'cygwin';

test_requires	'Test::More'		=> 0;
test_requires	'Test::Deep'		=> '0.103';
include		'Test::Deep';
include		'Test::Deep::*';
include		'Test::Deep::*::*';
test_requires	'End'			=> 0;
include		'End';

# --- Build data

install_script	'script/ccm_project_diff';

clean_files	't/zz_*.t';

no_index	module			=> 'VCS::CMSynergy::ObjectTieHash';
no_index	package			=> 'VCS::CMSynergy::Traversal';
no_index	package			=> 'Tie::ReadonlyArray';

WriteAll;


package MY;

sub postamble
{
    my $self = shift;

    # arrange for all tests to be run a second time with UseCoprocess => 1
    # (but only if we can find Expect.pm)
    if (eval { require Expect; import Expect 1.15; 1; })
    {
	print "Detected suitable version of Expect.pm, enabling tests with UseCoprocess => 1\n";

	foreach my $test (glob("t/*.t"))
	{
	    next if $test =~ m{^t/zz_};

	    open my $t, "<$test" or die "Can't read $test: $!";
	    next unless grep { /using coprocess/ } <$t>;
	    close $t;
	    
	    (my $zz_test = $test) =~ s{t/}{t/zz_};
	    open my $zz, ">$zz_test" or warn "Can't create $zz_test: $!";
	    print $zz <<"ZZ";
#!perl -w
\$ENV{CCM_USE_COPROCESS} = 1;
do '$test' or warn \$!;
die if \$\@;
exit 0;
ZZ
	    close $zz or warn "Error writing $zz_test: $!";
	}
    }

    return "";
}

sub post_initialize
{
    my $self = shift;

    # don't install Changes.pod as man page
    delete $self->{MAN3PODS}->{'lib/VCS/CMSynergy/Changes.pod'};

    return "";
}
