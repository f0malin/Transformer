use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Begin::Declare',
    license             => 'perl',
    dist_author         => q{Eric Strom <asg@cpan.org>},
    dist_version_from   => 'lib/Begin/Declare.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Devel::Declare' => 0,
    },
    add_to_cleanup      => [ 'Begin-Declare-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
