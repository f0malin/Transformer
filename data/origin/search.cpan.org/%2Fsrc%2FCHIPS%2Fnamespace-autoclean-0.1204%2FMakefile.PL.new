
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Keep imports out of your namespace',
  'AUTHOR' => 'Chip Salzenberg <chip@pobox.com>',
  'BUILD_REQUIRES' => {
    'Moose::Role' => '0',
    'Mouse' => '0',
    'Sub::Name' => '0',
    'Test::More' => '0',
    'overload' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'namespace-autoclean',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'namespace::autoclean',
  'PREREQ_PM' => {
    'B::Hooks::EndOfScope' => '0',
    'Class::MOP' => '0',
    'List::Util' => '0',
    'Package::Stash' => '0.21',
    'Sub::Identify' => '0',
    'namespace::clean' => '0.20'
  },
  'VERSION' => '0.1204',
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



