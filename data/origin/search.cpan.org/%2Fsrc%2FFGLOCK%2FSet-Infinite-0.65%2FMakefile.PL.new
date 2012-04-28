#!/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'ABSTRACT'        => 'Infinite Sets math',
    'AUTHOR'          => 'Flavio S. Glock <fglock@gmail.com>',
    'NAME'            => 'Set::Infinite',
    'VERSION_FROM'    => 'lib/Set/Infinite.pm',
    'EXCLUDE_EXT'     => [ qw(Makefile gz LOG x~~) ],
    'PREREQ_PM'       => { 
        'Time::Local'   => 0,
        'Test::More'    => 0, 
    },
    'dist'            => { 'COMPRESS' => 'gzip' },
);

