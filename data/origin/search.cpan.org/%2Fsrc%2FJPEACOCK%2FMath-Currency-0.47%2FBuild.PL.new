use Module::Build;
# See perldoc Module::Build for details of how this works
my $class = Module::Build->subclass
(
    class => 'My::Builder',
    code => q{
	sub ACTION_dist {
	    my $self = shift;
	    $self->do_system('hg log --style changelog > Changes');
	    $self->SUPER::ACTION_dist();
	}
    },
);

my $m = $class->new(
    module_name     => 'Math::Currency',
    license         => 'perl',
    requires        => {
	'Math::BigFloat' => '1.60',
    },
);
$m->create_build_script;

