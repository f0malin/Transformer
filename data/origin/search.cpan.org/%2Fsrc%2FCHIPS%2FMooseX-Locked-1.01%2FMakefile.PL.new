use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MooseX::Locked',
    AUTHOR              => q{Chip Salzenberg <chip@pobox.com>},
    VERSION_FROM        => 'lib/MooseX/Locked.pm',
    ABSTRACT_FROM       => 'lib/MooseX/Locked.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Moose'      => 2.0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MooseX-Locked-*' },
);
