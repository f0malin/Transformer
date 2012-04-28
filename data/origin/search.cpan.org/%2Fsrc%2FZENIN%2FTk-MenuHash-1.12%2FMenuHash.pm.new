package Tk::MenuHash;

=head1 NAME

Tk::MenuHash - Ties a Tk::Menubutton widget to a hash object thingy

=head1 SYNOPSIS

  use Tk::MenuHash;

  my $MB = new Tk::MenuHash ($Menubutton);
  my $MB = new Tk::MenuHash (
      $MW->Menubutton (
          -relief       => 'raised',
          -text         => 'Pick something',
          -underline    => 0,
      )->pack (
          -side         => 'left',
      )
  );

  $MB->{'Some list item label'}   = [ \&CommandFunction, 'args' ];
  $MB->{'Some other label'}       = \&CommandFunction;
  $MB->{'Some lable name'}        = 'default';

  delete $MB->{'Some other label'};

  $MB->configure ( -text => 'Pick something else' );

  my $menuText = $MB->{"Anything, it doesn't matter"};

  ##############################################################
  ## Or you can do it this way, but it needs two vars so I don't
  ## recommend it...

  tie my %MB, 'Tk::MenuHash', $Menubutton;
  ## Or...
  tie my %MB, 'Tk::MenuHash', $MW->Menubutton (
      -relief       => 'raised',
      -text         => 'Pick something',
      -underline    => 0,
  )->pack (
      -side         => 'left',
  );

  $MB{'Some list item label'}   = [ \&CommandFunction, 'args' ];
  $MB{'Some other label'}       = \&CommandFunction;
  $MB{'Some lable name'}        = 'default';

  delete $MB{'Some other label'};

  $Menubutton->configure ( -text => 'Pick something else' );

  my $menuText = $MB{"Anything, it doesn't matter"};

=cut

use strict;
use vars qw($VERSION @ISA $AUTOLOAD);
use Carp;
use Tk;

($VERSION)	= '$Revision: 1.12 $' =~ /\$Revision:\s+([^\s]+)/;

sub new {
	my $class	= shift;
		$class	= ref ($class) || $class;

	my $self	= {};

	tie %{ $self }, $class, @_;
	return bless $self, $class;
}

sub TIEHASH {
	my $class	= shift;
		$class	= ref ($class) || $class;

	my $self	= {};

	$self->{Menubutton}	= shift
		or confess "Invalid usage: no menubutton given";

	## Don't use these "features", yet...
	$self->{items}		= shift || {};
	my $default			= shift || 'default';

	bless $self, $class;

	## Incase we already have stuff in our hash:
	foreach my $label (sort { lc $a cmp lc $b } keys %{ $self->{items} }) {
		$self->STORE ($label, $default);
	}

	return $self;
}

sub STORE {
	my $self	= shift;
	my $label	= shift;
	my $subRef	= shift;

	## Default is just to select the current label
	if (not ref $subRef) {
		if ($subRef =~ /^default$/i) {
			my $menu	= $self->{Menubutton};
			$subRef		= sub { $menu->configure (-text => $label) };
		} else {
			confess qq(Non reference given as a command function);
		}
	}

	## No dup items are allowed in this type of class,
	## so nuke and replace.  Harmless if we don't have it yet.
	$self->DELETE ($label);

	$self->{items}{$label} = $subRef;

	return $self->{Menubutton}->command (
		-label		=> $label,
		-command	=> $subRef,
	);
}

sub DELETE {
	my $self	= shift;
	my $label	= shift;

	return unless (exists $self->{items}{$label});
	delete $self->{items}{$label};

	my $menu = $self->{Menubutton}->cget (-menu);
	$menu->delete ($label);
}

sub FETCH {
	my $self	= shift;
	return $self->{Menubutton}->cget (-text);
}

sub EXISTS {
	my $self	= shift;
	my $label	= shift;
	return 1 if (exists $self->{items}{$label});
	return;
}

sub CLEAR {
	my $self	= shift;
	foreach my $label (keys %{ $self->{items} }) {
		$self->DELETE ($label);
	}
	return 1;
}

sub FIRSTKEY {
	my $self	= shift;
	my $a		= scalar keys %{ $self->{items} };
	return each %{ $self->{items} };
}

sub NEXTKEY {
	my $self	= shift;
	return each %{ $self->{items} };
}

sub DESTROY {
	my $self	= shift;
	delete $self->{Menubutton};
}

sub AUTOLOAD {
	## Redirect all unknown methods to the Menubutton
	my $self	= shift;
	return if $AUTOLOAD =~ /::DESTROY$/;
	$AUTOLOAD	=~ s/^.*:://g;
	$self		= tied %{ $self };
	$self->{Menubutton}->$AUTOLOAD (@_);
}

1;

__END__

=head1 DESCRIPTION

Creates a tied B<Tk::Menubutton> widget hash reference object kinda
thingy....

It's actually much simplier then it sounds, at least to use.  It walks
and talks half like an object, and half like a (tied) hash reference.  This
is because it's both in one (it's a blessed reference to a tied hash of the
same class).

=over 4

=item B<WARNING>:

This is *not* a valid Tk widget as you would normally think of it.  You can
B<not> (currently) call it as

    my $menuHash = $MW->MenuHash(); ## Don't try this (yet)!

The B<2.x> release will be a true widget and thus walk and talk currently as
such.  As much as I will try and maintain this current API for future
compatibility, this may not be entire possible.  The B<2.x> release will
solidify this widget's API, but until then consider this API in a state of
flux.  Thanks

=back

When you add a key (label) to the hash it added it to the menubutton.  The
value assigned must be either a valid B<Tk::Menubutton> B<-command> option,
or the string B<'default'> (case is not important).  The B<default> is
simply a function that configure()s the Menubuttons B<-text> to that
of the selected label.  You can then retrieve the text by just reading
a key (any key, even if it doesn't exist, it doesn't matter) from the hash.

The new() method passes back a reference to a tie()d MenuHash,
but with all the properties (and methods) of the Menubutton you passed it.
With this type you can set and delete fields as hash keys references:

	$MenuHash->{'Some label'} = 'default';

But also call Tk::Menubutton (or sub-classes of it, if that's what you passed
the constructor) methods:

	$MenuHash->configure ( -text => 'Pick something' );

This involves B<black magic> to do, but it works.  See the B<AUTOLOAD> method
code if you have a morbid interest in this, however it's more that we are
dealing with 3 objects in 2 classes.

I prefer this useage myself as it meens I only need to carry around one var
that walks and talks almost exactly like a "real" B<Tk::Menubutton> (that
is, you can call any valid Tk::Menubutton method off it directly), but
with the added (and B<much> needed IMHO) feature of being able to easily
add, delete, select, and read menu options as simple hash ref keys.

=head1 EXAMPLE

  use Tk;
  use Tk::MenuHash;

  my $MW = new MainWindow;

  my $menu = new Tk::MenuHash ($MW->Menubutton (
      -relief       => 'raised',
      -text         => 'Pick something',
      -underline    => 0,
  )->pack (
      -side         => 'left',
  ));

  $menu->{'Option one (default)'}               = 'default';
  $menu->{'Option two (print "two")'}           = sub { print "two\n" };
  $menu->{'Option three (exit)'}                = sub { $MW->destroy };
  $menu->{'Option four (print current text)'}   = sub { print "$menu->{foobar}\n" };

  MainLoop;

=head1 AUTHOR

Zenin <zenin@bawdycaste.com>

aka Byron Brummer <byron@omix.com>

=head1 COPYRIGHT

Copyright (c) 1998, 1999 OMIX, Inc.

Available for use under the same terms as perl.

=cut
