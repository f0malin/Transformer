use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'autobox::dump',
    license             => 'perl',
    dist_author         => 'Chas. J Owens IV <chas.owens@gmail.com>',
    dist_version_from   => 'lib/autobox/dump.pm',
    build_requires      => {
        'Test::More' => 0,
	'autobox'    => 0,
    },
    add_to_cleanup      => [ 'autobox-dump-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
