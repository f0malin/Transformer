use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Perl6::Feeds',
    license            => 'perl',
    dist_author        => q{Eric Strom <ejstrom@gmail.com>},
    dist_version_from  => 'lib/Perl6/Feeds.pm',
	requires 		   => {
        perl 		   => '5.9.5'
    },
    build_requires     => {
		'Test::More'   => 0,
    },
    add_to_cleanup     => [ 'Perl6-Feeds-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
