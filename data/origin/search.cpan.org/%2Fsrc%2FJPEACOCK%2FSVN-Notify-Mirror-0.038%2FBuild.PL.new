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
    ( module_name     => 'SVN::Notify::Mirror',
      license         => 'perl',
      dist_author     => 'John Peacock <jpeacock@cpan.org>',
      sign            => 1,
      requires        => {
	  'Module::Build' => 0.2805,
	  'SVN::Notify'   => 2.70,
	  'YAML'          => 0.62,
      },
      auto_features   => {
	  ssh_support => { 
	      description => "Use remote mirrors via ssh",
	      requires    => {Net::SSH => 0.08 }
	  },
	  config_support => {
	      description => "Use compact YAML script",
	      requires    => {SVN::Notify::Config => 0.0906}
	  },
	  rsync_support => {
	      description => "Transfer files with rsync",
	      requires    => {File::Rsync => 0.42}
	  },
      },
      PL_files => { 
	  't/002_config.t.PL' =>
	      ['t/testconfig','t/002_config.t','t/002_config'],
	  't/003_sshtest.t.PL' => 't/003_sshtest.t',
	  't/004_rsynctest.t.PL' => 't/004_rsynctest.t',
      },
      add_to_cleanup =>
	  ['t/test-repos', 't/wc-*', 't/00[2-4]*.t'],
    );

if ( $mb->feature('ssh_support') ) {
    $mb->notes( sshtests => 1 ) if
    	$mb->y_n(
    "Do you want to run the SSH tests?\n".
    "(see the README for details)",'N');
}

if ( $mb->feature('rsync_support') ) {
    $mb->notes( rsynctests => 1 ) if
    	$mb->y_n(
    "Do you want to run the rsync tests?\n".
    "(see the README for details)",'N');
    	
    if ( $mb->notes('sshtests') && $mb->notes('rsynctests') ) {
	$mb->notes( rsyncsshtests => 1 ) if
	    $mb->y_n(
	"Do you want to run the rsync tests via SSH?\n".
	"(see the README for details)",'N');
    }
}

$mb->create_build_script;
