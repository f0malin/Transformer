use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lvalue',
    license             => 'perl',
    dist_author         => q{Eric Strom <asg@cpan.org>},
    dist_version_from   => 'lib/Lvalue.pm',
    build_requires => {
        'Test::More' => 0,
    },
	requires => {
		'strict'	   => 0,
		'warnings'     => 0,
		'Carp'		   => 0,
		'overload'     => 0,
		'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'Lvalue-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
