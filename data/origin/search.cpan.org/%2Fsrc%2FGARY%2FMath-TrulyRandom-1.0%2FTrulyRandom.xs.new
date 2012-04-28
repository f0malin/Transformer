/*
Perl Extension for the random function
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "truerand.h"

MODULE = Math::TrulyRandom		PACKAGE = Math::TrulyRandom

long
truly_random_value()
    CODE:
	{
		RETVAL = truerand();
	}
	OUTPUT:
	RETVAL
