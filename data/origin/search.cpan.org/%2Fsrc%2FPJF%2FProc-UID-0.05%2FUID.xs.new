/* XSUB bindings for Proc::UID.pm
 *
 * Paul Fenwick	<pjf@cpan.org>
 *
 * Copyright (c) 2004 Paul Fenwick.  All Rights reserved.  This
 * program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

/* TODO: Everything here uses type 'int' when it should use type
 * 'uid_t'.  On most systems they're the same, but we should not assume.
 *
 * However, XS _wants_ ints to be returned, since it knows how to deal with
 * them.  Can we trust the compiler to do the right thing with type
 * conversion?
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* This current works for Linux, what about other operating systems? */
#include <unistd.h>
#include <sys/types.h>
#include <sys/syscall.h>

#ifndef SYS_getresuid
	uid_t cached_suid;
	uid_t cached_sgid;
#endif

MODULE = Proc::UID  PACKAGE = Proc::UID

PROTOTYPES: DISABLE

# Low-level calls to get our privileges.
# These *should* always return the same as $< and $>, $( and $)

int
geteuid()
	CODE:
		RETVAL = geteuid();
	OUTPUT:
		RETVAL

int
getruid()
	CODE:
		RETVAL = getuid();
	OUTPUT:
		RETVAL

int
getegid()
	CODE:
		RETVAL = getegid();
	OUTPUT:
		RETVAL

int
getrgid()
	CODE:
		RETVAL = getgid();
	OUTPUT:
		RETVAL

# Get our saved UID/GID

#ifdef SYS_getresuid

int
suid_is_cached()
	CODE:
		RETVAL = 0;
	OUTPUT:
		RETVAL

int
getsuid()
	PREINIT:
		int ret;
		int ruid, euid, suid;
	CODE:
		ret = getresuid(&ruid, &euid, &suid);
		if (ret == -1) {
			croak("getresuid() returned failure.  Error in Proc::UID?");
		} else {
			RETVAL = suid;
		}
	OUTPUT:
		RETVAL

# Get our saved GID 

int
getsgid()
	PREINIT:
		int ret;
		int rgid, egid, sgid;
	CODE:
		ret = getresgid(&rgid, &egid, &sgid);
		if (ret == -1) {
			croak("getresgid() returned failure.  Error in Proc::UID?");
		} else {
			RETVAL = sgid;
		}
	OUTPUT:
		RETVAL

#else

# This records our saved privileges upon startup.  Yes, this is
# is caching.  I wish there were a better way.

int
suid_is_cached()
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
init()
	CODE:
		cached_suid = geteuid();
		cached_sgid = getegid();

int
getsuid()
	CODE:
		RETVAL = cached_suid;
	OUTPUT:
		RETVAL

int
getsgid()
	CODE:
		RETVAL = cached_sgid;
	OUTPUT:
		RETVAL

#endif

# Set our saved UID.

#ifdef SYS_setresuid

void
setsuid(suid)
		int suid;
	CODE:
		if (setresuid(-1,-1,suid) == -1) {
			croak("Could not set saved UID");
		}

# Set our saved GID.
void
setsgid(sgid)
		int sgid;
	CODE:
		if (setresgid(-1,-1,sgid) == -1) {
			croak("Could not set saved GID");
		}

#else

void
setsuid(suid)
		int suid;
	CODE:
		croak("setsuid cannot run without setresuid, which is not on this system.");

void
setsgid(sgid)
		int sgid;
	CODE:
		croak("setsgid cannot run without setresgid, which is not not on this system.");

#endif

# Preferred calls.

# drop_uid_temp - Drop privileges temporarily.
# Moves the current effective UID to the saved UID.
# Assigns the new_uid to the effective UID.
# Updates PL_euid

#ifdef SYS_setresuid

void
drop_uid_temp(new_uid)
		int new_uid;
	CODE:
		if (setresuid(-1,new_uid,geteuid()) < 0) {
			croak("Could not temporarily drop privs.");
		}
		if (geteuid() != new_uid) {
			croak("Dropping privs appears to have failed.");
		}
		PL_euid = new_uid;

# else /* No setresuid() */

void
drop_uid_temp(new_uid)
		int new_uid;
	CODE:
		int old_euid = geteuid();
		# This looks like a no-op, but actually sets the
		# SUID to the EUID.  Or *should*.
		if (setreuid(getruid(), old_euid) < 0) {
			croak("Could not use setreuid with same privs.");
		}
		if (seteuid(new_uid) < 0) {
			croak("Could not temporarily drop privs.");
		}
		if (geteuid() != new_uid) {
			croak("Dropping privs appears to have failed.");
		}
		cached_suid = old_euid;
		PL_euid = new_uid;

#endif /* setresuid */

# drop_uid_perm - Drop privileges permanently.
# Set all privileges to new_uid.
# Updates PL_uid and PL_euid
void
drop_uid_perm(new_uid)
		int new_uid;
	PREINIT:
		int ruid, euid, suid;
	CODE:
#ifdef SYS_setresuid
		if (setresuid(new_uid,new_uid,new_uid) < 0) {
			croak("Could not permanently drop privs.");
		}
		if (getresuid(&ruid, &euid, &suid) < 0) {
			croak("Could not check privileges were dropped.");
		}
		if (ruid != new_uid || euid != new_uid || suid != new_uid) {
			croak("Failed to drop privileges.");
		}
#else
		if (setreuid(new_uid, new_uid) < 0) {
			croak("Could not permanently drop privs.");
		}

		# Having a way to read the SUID would be great,
		# but depends upon the O/S.
		# XXX - For the moment we just assume this works for SUID

		if (getruid() != new_uid || geteuid() != new_uid) {
			croak("Failed to drop privileges.");
		}

		cached_suid = new_uid;
#endif
		PL_uid  = new_uid;
		PL_euid = new_uid;

void
restore_uid()
	PREINIT:
		int ruid, euid, suid;
	CODE:
#ifdef SYS_setresuid
		if (getresuid(&ruid, &euid, &suid) < 0) {
			croak("Could not verify privileges.");
		}
		if (setresuid(-1,suid,-1) < 0) {
			croak("Could not set effective UID.");
		}
		if (geteuid() != suid) {
			croak("Failed to set effective UID.");
		}
#else
		if (seteuid(cached_suid) < 0) {
			croak("Could not set effective UID.");
		}
		if (geteuid() != cached_suid) {
			croak("Failed to set effective UID.");
		}
#endif
		PL_euid = suid;

# Now let's do the same for gid functions.
# TODO - Think about getgroups / setgroups, how do they best fit in?

# XXX - These need to be fixed for resuid/non-resuid systems.

void
drop_gid_temp(new_gid)
		int new_gid;
	CODE:
		if (setresgid(-1,new_gid,getegid()) < 0) {
			croak("Could not temporarily drop privs.");
		}
		if (getegid() != new_gid) {
			croak("Dropping privs appears to have failed.");
		}
		PL_egid = new_gid;


void
drop_gid_perm(new_gid)
		int new_gid;
	PREINIT:
		int rgid, egid, sgid;
	CODE:
		if (setresgid(new_gid,new_gid,new_gid) < 0) {
			croak("Could not permanently drop privs.");
		}
		if (getresgid(&rgid, &egid, &sgid) < 0) {
			croak("Could not check privileges were dropped.");
		}
		if (rgid != new_gid || egid != new_gid || sgid != new_gid) {
			croak("Failed to drop privileges.");
		}
		PL_gid  = new_gid;
		PL_egid = new_gid;

void
restore_gid()
	PREINIT:
		int rgid, egid, sgid;
	CODE:
		if (getresgid(&rgid, &egid, &sgid) < 0) {
			croak("Could not verify privileges.");
		}
		if (setresgid(-1,sgid,-1) < 0) {
			croak("Could not set effective GID.");
		}
		if (getegid() != sgid) {
			croak("Failed to set effective GID.");
		}
		PL_egid = sgid;

