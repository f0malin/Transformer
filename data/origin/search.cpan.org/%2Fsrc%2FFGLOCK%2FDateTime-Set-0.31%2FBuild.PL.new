use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name   => 'DateTime::Set',
    dist_name     => 'DateTime-Set',
        dist_author   => 'Flavio S. Glock <fglock@gmail.com>',
        dist_abstract => 'DateTime set objects',
    license       => 'perl',
    requires      => {
        'DateTime'         => 0.12,
        'Set::Infinite'    => 0.59,
        'Test::More'       => 0,
        'Params::Validate' => 0,
    },
    conflicts => {
        'DateTime::Event::Recurrence' => '< 0.10',
        'DateTime::Event::ICal'       => '< 0.07',
        'DateTime::Event::Random'     => '< 0.03',
        'DateTime::Event::Cron'       => '<= 0.06',
        'DateTime::Event::Sunrise'    => '<= 0.05', # cvs ok; CPAN not ok
        'DateTime::Event::Chinese'    => '< 0',     # untested
        'DateTime::Event::Lunar'      => '< 0',     # untested
        'DateTime::Event::SolarTerm'  => '< 0',     # untested
    },
    # sign               => 1,
    # create_makefile_pl => 'passthrough'
);

$build->create_build_script;


