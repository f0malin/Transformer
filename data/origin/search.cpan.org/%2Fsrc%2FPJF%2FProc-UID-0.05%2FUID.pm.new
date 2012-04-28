=head1 NAME

Proc::UID - Manipulate a variety of UID and GID settings.

=head1 SYNOPSIS

	use Proc::UID qw(:vars);
	print "My saved-uid is $SUID, effective-uid is $EUID ",
	      "my real-uid is $RUID\n";

	use Proc::UID qw(:funcs);
	print "Permanently dropping privs to $new_gid and $new_uid\n";
	drop_gid_perm($new_gid); # Throws an exception on failure.
	drop_uid_perm($new_uid); # Throws an exception on failure.

	print "Saved-UIDs are cached\n" if suid_is_cached();

=head1 WARNING

If your code is running with additional privileges, it is recommended
that you I<always> carefully test and audit your code, including
this module if you use it.

This module is provided "as is", without warranty of any kind, either
express or implied, including, but limited to, the implied warranties
of merchantability and fitness for a particular purpose.

=head1 DESCRIPTION

Perl only has concepts of effective and real user-ids (UIDs) and 
group-ids (GIDs), accessible via the special variables $<, $>, $( and $).
However most modern Unix systems also have a concept of saved UIDs.

This module provides a consistent and logical interface to real,
effective, and saved UIDs and GIDs.  It also provides a way to
permanently drop privileges to that of a given user, a process
which C<$E<lt> = $E<gt> = $uid> does not guarantee, and the exact syntax
of which may vary from between operating systems.

C<Proc::UID> is also very pedantic about making sure that operations
succeeded, and checking the value which it returns for a UID/GID
really is the one that's being used.  Perl may sometimes cache
the values of $<, $>, $( and $), which means they can be wrong
after being changed with low-level system calls.

Proc::UID provides both a variable and function interfaces to
underlying UIDs.

=head1 DESIGN GOALS

Proc::UID is designed with the following goals in mind:

=over 4

=item The interface should be easy to understand.

The traditional POSIX L<setuid> function is notorious for being difficult
to understand.  The goal of Proc::UID is to provide an interface that
is straightforward and easy to understand, and that operates in the
same fashion regardless of operating system.

=item Mistakes should be difficult to make.

Any code that works with elevated privileges needs to be particularly
careful with its actions.  It would be a very Bad Thing if a program
were to continue operating believing it had dropped privileges when it
had not.

To best achieve this goal, Proc::UID will I<always> check the success of
any operation requested, and will generate an exception in the case of
failure.

Proc::UID also provides a set of functions with very clear names
that allow logical operations (temporarily drop privileges,
permanently drop privileges, and regain privileges) to be performed.
These logical operations are based upon the paper
"Setuid demystified", by Hao Chen, David Wagner, and Drew Dean.

=back

=head2 PREFERRED INTERFACE

The following interface is the preferred method to manipulate
a the UID/GID of a process.

=over 4

=item B<drop_uid_perm($uid)> and B<drop_gid_perm($gid)>

The C<drop_uid_perm> and C<drop_gid_perm> functions allow a program
to permanently drop its privileges to the given $uid or $gid.
It guarantees that the real, effective and saved uid/gid will be
set to the argument supplied.

If C<drop_uid_perm> or C<drop_gid_perm> cannot drop privileges, then
it will throw an exception.

=item B<drop_uid_temp($uid)> and B<drop_gid_temp($gid)>

These functions will allow privileges to be dropped in a temporary
fashion.  They have the effect of setting the effective uid to the
supplied argument, and the saved uid to the previous effective uid.
The real uid is not changed.

If privileges cannot be dropped, then the function will throw an
exception.

=item B<restore_uid()> and B<restore_gid()>

These functions will allow you to restore a privilege previously
dropped using C<drop_uid_temp> or C<drop_gid_temp>.  It is equivilent
to setting the effective uid/gid to the saved uid/gid.

=back

=head2 VARIABLE INTERFACE

If Proc::UID is called with the C<:vars> parameter, the following
variables will be made available:

=over 4

=item B<$EUID>

This is the effective UID of the process.  It is nominally the same
as $>.  However reading C<$EUID> I<always> results in the effective
UID of the process being read.  Setting C<$EUID> will result in an exception
being thrown if it does not succeed.

=item B<$RUID>

As above, but for the real UID.  Nominally the same as $<.

=item B<$SUID>

As above, but for the saved UID.  There is no equivilent special
variable in Perl.

=back

=head2 FUNCTIONAL INTERFACE

=over 4

=item B<geteuid()> / B<getegid()>

=item B<getruid()> / B<getrgid()>

=item B<getsuid()> / B<getsgid()>

Return the effective, real, or saved user-id/group-id respectively.
These functions will always make a system call to get the current
value.

=item B<seteuid($uid)> / B<setegid($gid)>

=item B<setruid($uid)> / B<setrgid($gid)>

=item B<setsuid($uid)> / B<setsgid($gid)>

Set the effective, real, or saved user-id/group-id respectively.
If the operation fails, an exception will be thrown.

=item suid_is_cached()

Not all systems support direct manipulation of the saved UID, or
require use of system calls which C<Proc::UID> does not yet
understand.

Since the saved UID is always equal to the effective UID when a
process starts, C<Proc::UID> can infer the value of the saved
UID even if it can't read it directly.  If this is the case,
then C<suid_is_cached> will return true.

If C<suid_is_cached> returns false, then you're running on a
system where C<Proc::UID> knows how to directly manipulate saved
UIDs.

=back

=head1 BUGS

Many operating systems have different interfaces into their
extra UIDs.  This module has not yet been tested under all of
them.

The module does not manipulate or make available access to any
other operating-system-specific privileges, such as the filesystem
UID under Linux.

=head1 LICENSE

Copyright (c) 2004-2008 Paul Fenwick E<lt>pjf@cpan.orgE<gt>.  All
rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 TESTING STRATEGY

Proc::UID's testing strategy is intended to be very complete.  Should
any tests fail when building C<Proc::UID> on your system, then it is
recommended that you do not use C<Proc::UID>, and report the failing
tests to the author.

For complete testing, C<Proc::UID>'s tests need to run as root.

=head1 SEE ALSO

L<perlsec> and L<perlvar>

Perl Training Australia's I<Perl Security> course manual,
available from L<http://perltraining.com.au/notes.html>

Setuid Demystified, L<http://www.cs.berkeley.edu/~hchen/paper/usenix02.html>

L<Unix::SavedIDs>, L<Unix::SetUser>

=cut

package Proc::UID;
use strict;
use warnings;
use 5.006;
use DynaLoader;
use Exporter;
use Carp;
use vars qw($SUID $SGID $EUID $RUID $EGID $RGID);

our $VERSION = 0.05;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT_OK = qw(	getruid geteuid getrgid getegid
			setruid seteuid setrgid setegid
			getsuid getsgid setsuid setsgid
			suid_is_cached
			drop_uid_temp drop_uid_perm restore_uid
			drop_gid_temp drop_gid_perm restore_gid
			$RUID $EUID $RGID $EGID $SUID $SGID);

our %EXPORT_TAGS = (
	vars  => [qw(	$RUID $EUID $RGID $EGID $SUID $SGID)],
	funcs => [qw(	getruid geteuid getrgid getegid
			setruid seteuid setrgid setegid
			getsuid getsgid setsuid setsgid
			suid_is_cached
			drop_uid_temp drop_uid_perm restore_uid
			drop_gid_temp drop_gid_perm restore_gid
	)],
);

# Most of our hard work is done in XS.
# XSLoader::load 'Proc::UID';

bootstrap Proc::UID;

# Ties for SUID/SGID

tie $SUID, 'Proc::UID::SUID';
tie $SGID, 'Proc::UID::SGID';
tie $EUID, 'Proc::UID::EUID';
tie $RUID, 'Proc::UID::RUID';
tie $EGID, 'Proc::UID::EGID';
tie $RGID, 'Proc::UID::RGID';

# These use Perl's interface to set privileges, as that handles updating
# of PL_uid, PL_euid, etc for us.  However they die in the case of an
# updating failure.

sub setruid { $< = $_[0]; croak "setruid failed" unless ($_[0] == $<); }
sub seteuid { $> = $_[0]; croak "seteuid failed" unless ($_[0] == $>); }
sub setrgid { $( = $_[0]; croak "setrgid failed" unless ($_[0] == $(); }
sub setegid { $) = $_[0]; croak "setegid failed" unless ($_[0] == $)); }

# Packages for tied variables are from here on.
# Saved [UG]ID...
package Proc::UID::SUID;
sub TIESCALAR { my $val; return bless \$val, $_[0]; }
sub FETCH     { return Proc::UID::getsuid(); }
sub STORE     { return Proc::UID::setsuid($_[1]); }

package Proc::UID::SGID;
sub TIESCALAR { my $val; return bless \$val, $_[0]; }
sub FETCH     { return Proc::UID::getsgid(); }
sub STORE     { return Proc::UID::setsgid($_[1]); }

# Regular UIDs
package Proc::UID::RUID;
sub TIESCALAR { my $val; return bless \$val, $_[0]; }
sub FETCH     { return Proc::UID::getruid(); }
sub STORE     { return Proc::UID::setruid($_[1]); }

package Proc::UID::EUID;
sub TIESCALAR { my $val; return bless \$val, $_[0]; }
sub FETCH     { return Proc::UID::geteuid(); }
sub STORE     { return Proc::UID::seteuid($_[1]); }

# Regular GIDs
package Proc::UID::RGID;
sub TIESCALAR { my $val; return bless \$val, $_[0]; }
sub FETCH     { return Proc::UID::getrgid(); }
sub STORE     { return Proc::UID::setrgid($_[1]); }

package Proc::UID::EGID;
sub TIESCALAR { my $val; return bless \$val, $_[0]; }
sub FETCH     { return Proc::UID::getegid(); }
sub STORE     { return Proc::UID::setegid($_[1]); }

1;
