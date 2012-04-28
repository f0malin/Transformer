package App::Packer::Temp;

use strict;
use vars qw($VERSION);
use Config;

$VERSION = '0.12';

sub new 
{
	my ($type, %args) = @_;

	my $class = ref $type || $type;
	my $self  = bless {}, $class;

	# apply default values for frontend/backend
	$args{frontend} ||= 'App::Packer::Frontend::ModuleInfo';
	$args{backend} ||= 'App::Packer::Backend::DemoPack';

	# automatically require default frontend/backend
	if( $args{frontend} eq 'App::Packer::Frontend::ModuleInfo' ) 
	{
		require App::Packer::Frontend::ModuleInfo;
	}
	else
	{
		_require($args{frontend});
	}

	if( $args{backend} eq 'App::Packer::Backend::DemoPack' ) 
	{
		require App::Packer::Backend::DemoPack;
	}
	else
	{
		_require($args{backend});
	}	

	my $fe = $self->{FRONTEND} = 
			($args{frontend}->can('new'))? $args{frontend}->new : $args{frontend};

	my $be = $self->{BACKEND} = 
			($args{backend}->can('new'))? $args{backend}->new : $args{backend};


	$self->_set_args( %args );
	$self->_set_options( %args );

	$be->set_front($fe) if ($be->can('set_front'));

	return $self;
}

sub _set_options
{
	my ($self, %args) = @_;

	my $fe = $self->frontend();
	my $be = $self->backend();

	my $frontopts	= $args{frontopts} || $args{opts} || undef;
	my $backopts	= $args{backopts}  || $args{opts} || undef;

	$fe->set_options(%$frontopts) if ($fe->can('set_options') && $frontopts);
	$be->set_options(%$backopts)  if ($be->can('set_options') && $backopts);
}

sub _set_args
{
	my ($self, %args) = @_;

	my $fe = $self->frontend();
	my $be = $self->backend();

	my $frontargs 	= $args{frontargs} || $args{args} || undef;
	my $backargs 	= $args{backargs}  || $args{args} || undef;

	return() if (!$frontargs && !$backargs);

	$fe->set_args(@$frontargs) if ($fe->can('set_args') && $frontargs);
	$be->set_args(@$backargs)  if ($be->can('set_args') && $backargs);
}

sub set_file 
{
  my $self = shift;
  my $file = shift;

  warn( "File not found '$file'" ), return unless -f $file;

  $self->backend->set_file($file);

  return 1;
}

sub go
{
	my ($self) = @_;

	my $fe = $self->frontend();
	my $be = $self->backend();

	$fe->go() if ($fe->can('go'));
	$be->go() if ($be->can('go'));
}

sub generate_pack
{
	my ($self, %opt) = @_;

	my $be = $self->backend();
	$be->generate_pack(%opt);
}

sub run_pack
{
	my ($self, %opt) = @_;

	my $be = $self->backend();
	$be->run_pack(%opt);
}

sub add_manifest
{
	my ($self) = @_;

	my $be = $self->backend();
	return($be->add_manifest());
}

sub pack_manifest
{
	my ($self) = @_;
	my $be = $self->backend();
	return($be->pack_manifest());
}

sub write 
{
  my $self= shift;
  my $exe = shift;
  my $ret = 1;

  # attach exe extension
  $exe .= $Config{_exe} unless $exe =~ m/$Config{_exe}$/i;

  # write file
  $self->frontend->calculate_info;
  my $files = $self->frontend->get_files;
  $ret &= $files ? 1 : 0;
  $ret &= $self->backend->set_files( %$files );
  $ret &= $self->backend->write( $exe );

  chmod 0755, $exe if $ret;

  $ret ? return $exe : return;
}

sub set_options 
{
  my $self = shift;
  my %args = @_;

  if ( exists $args{frontend} ) 
  {
    $self->frontend->set_options( %{$args{frontend}} );
  }

  if( exists $args{backend} ) 
  {
    $self->backend->set_options( %{$args{backend}} );
  }
}

sub add_back_options
{
	my ($self, %opt) = @_;
	$self->backend->add_options(%opt);
}

sub add_front_options
{
	my ($self, %opt) = @_;
	$self->frontend->add_options(%opt);
}

sub frontend { $_[0]->{FRONTEND} || die "No frontend available" }
sub backend { $_[0]->{BACKEND} || die "No backend available" }

sub _require
{
	my ($text) = @_;
	eval ( "require $text"); 
	die $@ if $@;
}
1;

__END__

=head1 NAME

App::Packer - pack applications in a single executable file

=head1 DESCRIPTION

App::Packer packs perl scripts and all of their dependencies inside
an executable.

=head1 RETURN VALUES

All methods return a false value on failure, unless otherwise specified.

=head1 METHODS

=head2 new

  my $packer = App::Packer->new( frontend => class,
                                 backend  => class );

Creates a new C<App::Packer> instance, using the given classes as
frontend and backend.

'frontend' defaults to C<App::Packer::Frontend::ModuleInfo>, 'backend'
to C<App::Packer::Backend::DemoPack>. You need to C<use My::Module;>
if you pass C<My::Module> as frontend or backend, I<unless> you use
the default value.

Currently known frontends are C<App::Packer::Frontend::ModuleInfo>
(default, distributed with C<App::Packer>), and C<Module::ScanDeps>.

Currently known backends are C<App::Packer::Backend::DemoPack>
(default, distributed with C<App::Packer>), and
C<App::Packer::Backend::PAR>.

=head2 set_file

  $packer->set_file( 'path/to/file' );

Sets the file name of the script to be packed.

=head2 write

  my $file = $packer->write( 'my_executable' );

Writes the executable file; the file name is just the basename of the file:
$Config{_exe} will be appended, and the file will be made executable
(via chmod 0755).

The return value is the file name that was actually created.

=head2 set_options

  $packer->set_options( frontend => { option1 => value1,
                                      ... },
                        backend  => { option9 => value9,
                                      ... },
                       );

Sets the options for frontend and backend; see the documentation
for C<App::Packer::Frontend> and C<App::Packer::Backend> for details.

=head1 SEE ALSO

L<App::Packer::Frontend|App::Packer::Frontend>,
L<App::Packer::Backend|App::Packer::Backend>.

=head1 AUTHOR

Mattia Barbon <mbarbon@dsi.unive.it>

=cut

# local variables:
# mode: cperl
# end:
