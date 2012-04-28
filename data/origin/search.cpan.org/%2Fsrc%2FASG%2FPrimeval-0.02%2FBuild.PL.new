use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Primeval',
    license             => 'perl',
    dist_author         => q{Eric Strom <asg@cpan.org>},
    dist_version_from   => 'lib/Primeval.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Primeval-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
