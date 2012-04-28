# RWLock.pm
#
# Copyright (c) 2001 Andreas Ferber. All rights reserved.
#
# $Id: RWLock.pm,v 1.2 2001/06/29 02:11:49 af Exp $

=head1 NAME

Thread::RWLock - rwlock implementation for perl threads

=head1 SYNOPSIS

    use Thread::RWLock;

    my $rwlock = new Thread::RWLock;

    # Reader
    $rwlock->down_read;
    $rwlock->up_read;

    # Writer
    $rwlock->down_write;
    $rwlock->up_write;

=head1 DESCRIPTION

RWLocks provide a mechanism to regulate access to resources.
Multiple concurrent reader may hold the rwlock at the same
time, while a writer holds the lock exclusively.

New reader threads are blocked if any writer are currently waiting to
obtain the lock. The read lock gets through after all write lock
requests have completed.

This RWLock implementation also takes into account that one thread may
obtain multiple readlocks at the same time and prevents deadlocking in
this case.

=cut

package Thread::RWLock;

use Thread qw(cond_wait cond_broadcast);

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
}

=head1 FUNCTIONS AND METHODS

=over 8

=item new

C<new> creates a new rwlock. The new rwlock is unlocked.

=cut

sub new {
    my $class = shift;

    my $self = {};

    $self->{locks} = 0;
    $self->{locker} = {};
    $self->{writer} = 0;

    return bless $self, $class;
}

=item down_read

The C<down_read> method obtains a read lock. If the lock is currantly
held by a writer or writer are waiting for the lock, C<down_read> blocks
until the lock is available.

=cut

sub down_read :locked method {
    my $self = shift;

    if ($self->{locker}->{Thread->self->tid}++) {
        return;
    }

    cond_wait $self until $self->{locks} >= 0 && $self->{writer} == 0;

    $self->{locker}->{Thread->self->tid} = 1;
    $self->{locks}++;
}

=item up_read

Releases a read lock previously obtained via C<down_read>.

=cut

sub up_read :locked method {
    my $self = shift;

    if (--$self->{locker}->{Thread->self->tid} == 0) {
        $self->{locks}--;
        if ($self->{locks} == 0) {
            cond_broadcast $self;
        }
    }
}

=item down_write

Obtains a write lock from the rwlock. Write locks are exclusive, so no
other reader or writer are allowed until the lock is released.
C<down_write> blocks until the lock is available.

=cut

sub down_write :locked method {
    my $self = shift;

    $self->{writer}++;
    cond_wait $self until $self->{locks} == 0;
    $self->{locks}--;
}

=item up_write

Release a write lock previously obtained via C<down_write>.

=cut

sub up_write :locked method {
    my $self = shift;

    $self->{writer}--;
    $self->{locks} = 0;
    cond_broadcast $self;
}

=back

=head1 SEE ALSO

the Thread::Semaphore manpage

=head1 AUTHOR

Andreas Ferber <aferber@cpan.org>

=cut

1;
