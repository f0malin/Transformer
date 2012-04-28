use Module::Build;
# See perldoc Module::Build for details of how this works

my $class = Module::Build->subclass
(
    class => 'JPEACOCK::Builder',
    code => q{
	sub ACTION_dist{
	    my $self = shift;
	    $self->do_system('my-changelog.pl > Changes');
	    $self->SUPER::ACTION_dist();
	}
    }
);

my $mb = $class->new
    ( module_name     => 'SVN::Notify::Snapshot',
      license         => 'perl',
      dist_author     => 'John Peacock <jpeacock@cpan.org>',
      sign            => 1,
      requires        => {
	  'Module::Build' => 0.2805,
	  'SVN::Notify'   => 2.62,
      },
      auto_features   => {
	  config_support => {
	      description => "Use compact YAML script",
	      requires    => {SVN::Notify::Config => 0.0906}
	  },
      },
      PL_files => { 
	  't/002_config.t.PL' =>
	      ['t/testconfig','t/002_config.t','t/002_config'],
      },
      add_to_cleanup =>
	  ['t/test-repos', 't/testconfig', 't/002_config.t',
	  't/002_config', 't/*.tgz'],
    );

$mb->create_build_script;
