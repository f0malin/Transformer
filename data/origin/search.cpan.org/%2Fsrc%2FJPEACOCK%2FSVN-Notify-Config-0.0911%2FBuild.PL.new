use Module::Build;
# See perldoc Module::Build for details of how this works

my $class = Module::Build->subclass
(
    class => 'JPEACOCK::Builder',
    code => q{
	sub ACTION_dist {
	    my $self = shift;
	    $self->do_system('my-changelog.pl > Changes');
	    $self->SUPER::ACTION_dist();
	}
    }
);

my $mb = $class->new
    ( module_name     => 'SVN::Notify::Config',
      license         => 'perl',
      dist_author     => 'John Peacock <jpeacock@cpan.org>',
      requires        => {
	  'Module::Build' => 0.2805,
	  'SVN::Notify'   => 2.70,
	  'YAML'          => 0.62,
      },
      build_requires  => {
	  'Test::Deep'    => 0.100,
      },
      sign            => 1,
      add_to_cleanup =>
	  ['t/test-repos', ],
    );

exit 0 unless found_svnlook();

$mb->create_build_script;

sub found_svnlook {
    eval "use SVN::Notify";
    return 0 if $@;
    my $svnlook = SVN::Notify->find_exe('svnlook');
    unless ( defined $svnlook ) {
	warn "This module requires svnlook";
	return 0;
    }
    return 1;
}
