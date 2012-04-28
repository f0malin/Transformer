
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A date and time object',
  'AUTHOR' => 'Dave Rolsky <autarch@urth.org>',
  'BUILD_REQUIRES' => {
    'ExtUtils::CBuilder' => '0',
    'Pod::Man' => '1.14',
    'Test::Exception' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.36'
  },
  'DISTNAME' => 'DateTime',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'DateTime',
  'PREREQ_PM' => {
    'DateTime::Locale' => '0.41',
    'DateTime::TimeZone' => '1.09',
    'Params::Validate' => '0.76',
    'Scalar::Util' => '0',
    'Time::Local' => '1.04'
  },
  'VERSION' => '0.57',
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



