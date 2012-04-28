use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'List::Gen',
    license            => 'perl',
    dist_author        => q{Eric Strom <asg@cpan.org>},
    dist_version_from  => 'lib/List/Gen.pm',
    requires           => {perl => '5.8.6'},
    add_to_cleanup     => ['List-Gen-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
