use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Unicode::Digits',
    license             => 'perl',
    dist_author         => 'Chas. J. Owens IV <chas.owens@gmail.com>',
    dist_version_from   => 'lib/Unicode/Digits.pm',
    build_requires => {
	'warnings'     => 0,
	'strict'       => 0,
	'Carp'         => 0,
	'Unicode::UCD' => 0,
	'Exporter'     => 0,
        'Test::More'   => 0,
    },
    add_to_cleanup      => [ 'Unicode-Digits-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
