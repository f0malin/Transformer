use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Hash::Abbrev',
    license             => 'perl',
    dist_author         => q{Eric Strom <asg@cpan.org>},
    dist_version_from   => 'lib/Hash/Abbrev.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Text::Abbrev' => 0,
        'Hash::Util'   => 0,
    },
    add_to_cleanup      => [ 'Hash-Abbrev-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
