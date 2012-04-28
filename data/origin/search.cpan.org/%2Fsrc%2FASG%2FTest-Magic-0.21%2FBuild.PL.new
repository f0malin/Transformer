use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Magic',
    license             => 'perl',
    dist_author         => q{Eric Strom <asg@cpan.org>},
    dist_version_from   => 'lib/Test/Magic.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Test-Magic-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
