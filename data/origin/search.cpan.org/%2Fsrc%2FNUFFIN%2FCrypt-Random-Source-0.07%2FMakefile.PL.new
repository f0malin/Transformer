
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Get weak or strong random data from pluggable sources',
  'AUTHOR' => 'Yuval Kogman <nothingmuch@woobling.org>',
  'BUILD_REQUIRES' => {
    'IO::Select' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Crypt-Random-Source',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Crypt::Random::Source',
  'PREREQ_PM' => {
    'Any::Moose' => '0.11',
    'Capture::Tiny' => '0.08',
    'Carp' => '0',
    'Errno' => '0',
    'File::Spec' => '0',
    'IO::File' => '0',
    'IO::Handle' => '0',
    'Module::Find' => '0',
    'Sub::Exporter' => '0',
    'bytes' => '0',
    'namespace::clean' => '0.08'
  },
  'VERSION' => '0.07',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



