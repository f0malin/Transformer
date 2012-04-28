use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Whatever',
    license             => 'perl',
    dist_author         => q{Eric Strom <asg@cpan.org>},
    dist_version_from   => 'lib/Whatever.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Magic' => 0,
    },
    add_to_cleanup      => [ 'Whatever-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
