# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use Tk::MenuHash;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $MW	= new MainWindow
	or die $!;

my $menu = new Tk::MenuHash ($MW->Menubutton (
	-relief       => 'raised',
	-text         => 'Pick something',
	-underline    => 0,
)->pack (
	-side         => 'left',
));

$menu->{'Option one (default)'}				= 'default';
$menu->{'Option two (print "two")'}			= sub { print "two\n" };
$menu->{'Option three (exit)'}				= sub { $MW->destroy };
$menu->{'Option four (print current text)'}	= sub { print "$menu->{foobar}\n" };

MainLoop;
