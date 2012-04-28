use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'here',
    license             => 'perl',
    dist_author         => q{Eric Strom <asg@cpan.org>},
    dist_version_from   => 'lib/here.pm',
    build_requires      => {
        'Test::More'         => 0,
        'Filter::Util::Call' => 0,
    },
    add_to_cleanup      => [ 'here-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
