#!/usr/bin/perl

use Module::Build;
my $class = Module::Build->subclass
(
    class => 'version::Builder',
    code => q{
    sub ACTION_dist{
        my $self = shift;
    	$self->do_system('svk log -v | gnuify-changelog.pl > Changes');
	$self->SUPER::ACTION_dist();
	}
    },
);

my $m = $class->new(
    module_name     => 'version::AlphaBeta',
    license         => 'perl',
    requires        => {version => '0.32',},
);
$m->create_build_script;
