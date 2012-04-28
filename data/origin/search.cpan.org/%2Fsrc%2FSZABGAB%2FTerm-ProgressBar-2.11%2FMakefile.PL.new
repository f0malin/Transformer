require 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'Term-ProgressBar',
  VERSION_FROM => 'lib/Term/ProgressBar.pm',
  AUTHOR       => 'Martyn J. Pearce ',
#  ABSTRACT     => 'provide a progress meter on a standard terminal',
  PREREQ_PM    => { 
                     'Class::MethodMaker' => '1.02',
                     'Term::ReadKey' => '2.14',
  },
  BUILD_REQUIRES => {
                     'Capture::Tiny' => '0.13',
                     'Test::More'    => '0.80',
                     'Test::Exception' => '0.31',
                     'File::Temp'    => 0,
  },
);
