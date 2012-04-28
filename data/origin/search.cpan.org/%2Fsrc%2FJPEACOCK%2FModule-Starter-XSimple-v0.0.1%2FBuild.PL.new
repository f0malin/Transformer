use strict;
use warnings;
use Module::Build;
my $class = Module::Build->subclass
(
    class => 'JPEACOCK::Builder',
    code => q{
	sub ACTION_dist{
	    my $self = shift;
	    $self->do_system('svk log -x | gnuify-changelog.pl > Changes');
	    $self->SUPER::ACTION_dist();
	}
    }
);

my $builder = $class->new(
    module_name         => 'Module::Starter::XSimple',
    license             => 'perl',
    dist_author         => 'John Peacock <jpeacock@cpan.org>',
    dist_version_from   => 'lib/Module/Starter/XSimple.pm',
    requires => {
	'Module::Starter' => 1.42,
	'Test::More'      => 0.54,
	'version'         => 0.49,
	'Devel::PPPort'   => 3.06,
    },
    add_to_cleanup      => [ 'Module-Starter-XSimple-*' ],
);

$builder->create_build_script();
