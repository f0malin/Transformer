package CGI::Validate;

=head1 NAME

CGI::Validate - Advanced CGI form parser and type validation

=head1 SYNOPSIS

  use CGI::Validate;                # GetFormData() only
  use CGI::Validate qw(:standard);  # Normal use
  use CGI::Validate qw(:subs);      # Just functions
  use CGI::Validate qw(:vars);      # Just exception vars

  ## If you don't want it to check that every requested
  ## element arrived you can use this.  But I don't recommend it
  ## for most users.
  $CGI::Validate::Complete = 0;

  ## If you don't care that some fields in the form don't
  ## actually match what you asked for. -I don't recommend
  ## this unless you REALLY know what you're doing because this
  ## normally meens you've got typo's in your HTML and we can't
  ## catch them if you set this.
  ## $CGI::Validate::IgnoreNonMatchingFields = 1;

  my $FieldOne    = 'Default String';
  my $FieldTwo    = 8;
  my $FieldThree  = 'some default string';
  my @FieldFour   = ();  ## For multi-select field
  my @FieldFive   = ();  ## Ditto
  my $EmailAddress= '';

  ## Try...
  my $Query = GetFormData (
      'FieldOne=s'  => \$FieldOne,     ## Required string
      'FieldTwo=i'  => \$FieldTwo,     ## Required int
      'FieldThree'  => \$FieldThree,   ## Auto converted to the ":s" type
      'FieldFour=s' => \@FieldFour,    ## Multi-select field of strings
      'FieldFive=f' => \@FieldFive,    ## Multi-select field of floats
      'Email=e'     => \$EmailAddress, ## Must 'look' like an email address
  ) or do {
      ## Catch... (wouldn't you just love a case statement here?)
      if (%Missing) {
          die "Missing form elements: " . join (' ', keys %Missing);
      } elsif (%Invalid) {
          die "Invalid form elements: " . join (' ', keys %Invalid);
      } elsif (%Blank) {
          die "Blank form elements: " . join (' ', keys %Blank);
      } elsif (%InvalidType) {
          die "Invalid data types for fields: " . join (' ', keys %InvalidType);
      } else {
          die "GetFormData() exception: $CGI::Validate::Error";
      }
  };

  ## If you only want to check the form data, but don't want to
  ## have CGI::Validate set anything use this. -You still have full
  ## access to the data via the normal B<CGI> object that is returned.

  use CGI::Validate qw(CheckFormData); # not exported by default
  my $Query = CheckFormData (
    'FieldOne=s',   'FieldTwo=i',   'FieldThree',   'FieldFour',
    'FieldFive',    'Email',
  ) or do {
      ... Same exceptions available as GetFormData above ...
  };

  ## Need some of your own validation code to be used?  Here is how you do it.
  addExtensions (
      myType   => sub { $_[0] =~ /test/ },
      fooBar   => \&fooBar,
      i_modify_the_actual_data => sub {
          if ($_[0] =~ /test/) {   ## data validation
              $_[0] = 'whatever';  ## modify the data by alias
              return 1;
          } else {
              return 0;
          }
     },
  );
  my $Query = GetFormData (
      'foo=xmyType'    => \$foo,
      'bar=xfooBar'    => \$bar,
      'cat=xi_modify_the_actual_data' => \$cat,
  );


  ## Builtin data type checks available are:
  s    string     # Any non-zero length value
  w    word       # Must have at least one \w char
  i    integer    # Integer value
  f    float      # Float value
  e    email      # Must match m/^\s*<?[^@<>]+@[^@.<>]+(?:\.[^@.<>]+)+>?\s*$/
  x    extension  # User extension type.  See EXTENSIONS below.


=cut

BEGIN { require 5.004 }
use strict;
use vars qw(
	@EXPORT		@EXPORT_OK	%EXPORT_TAGS	$VERSION	@ISA
	$Complete	$IgnoreNonMatchingFields	$Error
	%Missing	%Invalid	%Blank			%InvalidType
);
require Exporter;
@ISA		= qw(Exporter);
@EXPORT		= qw(GetFormData);
@EXPORT_OK	= qw(%Missing %Invalid %Blank %InvalidType addExtensions GetFormData CheckFormData);
%EXPORT_TAGS = (
	standard	=> [ @EXPORT_OK ],
	all			=> [ @EXPORT_OK ], # depreciated
	vars		=> [ qw(%Missing %Invalid %Blank %InvalidType) ],
	subs		=> [ qw(addExtensions GetFormData CheckFormData) ],
);
$VERSION = do { my @r = (q$Revision: 2.0 $ =~ /\d+/g); sprintf '%d.%03d'.'%02d' x ($#r-1), @r};

use CGI 2.30;
use Carp;

## User settable globals
$Complete = 1;
$IgnoreNonMatchingFields = 0;

## Code settable globals
my %TYPES = (
	's'	=> [ 'string',	\&CheckString	],
	'w'	=> [ 'word',	\&CheckWord		],
	'i'	=> [ 'integer',	\&CheckInt		],
	'f' => [ 'float',	\&CheckFloat	],
	'e' => [ 'email',	\&CheckEmail	],
	'x'	=> [ 'extension',	sub { confess q(PANIC: Can't Happen[tm]: Sorry, but type 'x' is not supported in raw form.  See EXTENSIONS in perldoc ) . __FILE__ . '. ' } ],
);

sub addExtensions {
	my %exts	= @_
		or confess qq(usage: addExtentions ('name' => sub { validation code }));
	while (my ($ext, $sub) = each %exts) {
		ref $sub eq 'CODE'
			or confess qq($sub is not a CODE ref for extension type '$ext');
		$TYPES{"x$ext"} = [ "x$ext", $sub ];
	}
}

sub GetFormData {
	my %fields		= ();	## We load this latter from @_
	my %form		= ();	## Values from the form actually gave us

	## Damn CGI changed it's frigging interface... :-(
	my $query		= new CGI;
	%form			= %{ $query };

## Use this code below if the CGI object form gets changed.  Yes, we're breaking OO rules, so kill me I need the speed!
#	foreach my $name ($query->param) {
#		$form{$name} = [ $query->param ($name) ];
#	}

	%Missing		= ();	## We use these to do our $Complete testing
 	%Invalid		= ();	## Fields they didn't ask for
	%Blank			= ();	## Fields left blank, that have a required modifier
	%InvalidType	= ();	## Fields with data not matching there type defs

	## Program's validation spec part
	## Load %fields, and add :s type to fields that don't contain one
	for (my $arg=0; $arg <= $#_; $arg += 2) {
		## Split field in to name, if it's optional, and it's required type
		my ($field, $optional, $type) = ($_[$arg] =~ /^([^:=]+)([:=]?)(\w*)/);

		## Moron check...
		unless ($field) { $Error = qq(Invalid arg "$_[$arg]" given to GetFormData(): No field name???); return }

		## Optional argument, or required?  Default optional
		$optional = $optional eq '=' ? 0 : 1;

		$type ||= 's';  ## Default optional string

		$TYPES{$type}
			or ($Error = qq(Invalid type "$type" given for field "$field"), return);
		$type = $TYPES{$type};

		$fields{$field}{reference} = $_[ $arg + 1 ]
			or ($Error = qq(No place given to stick the value for "$field"), return);
		## Check for correct reference type
		(ref $fields{$field}{reference} eq 'SCALAR') || (ref $fields{$field}{reference} eq 'ARRAY')
			or ($Error = qq(Invalid reference type "@{[ ref ($fields{$field}{reference}) ]}" given for "$field".  Must be SCALAR or ARRAY), return);

		$fields{$field}{optional}	= $optional;
		$fields{$field}{type}		= $type;
	}

	## $Complete checking:
	if ($Complete) {
		foreach my $field (keys %fields) {
			## Make sure we have it
	 		unless (exists $form{$field}) {
				$Missing{$field} = qq(Missing required form element "$field");
	 		}
	 	}
	}

	## Form's data
	## Check all form fields for type et al...
	foreach my $field ($query->param) {
		## Did we get a bad field from the form?
		unless (exists $fields{$field}) {
			## Do we care?
			unless ($IgnoreNonMatchingFields) {
				# push @Invalid, "Non-matching field: $field";
				$Invalid{$field} = "Non-matching field: $field";
			}
			next;
		}

		# my @values = $query->param ($field);

		unless (scalar @{ $form{$field} } or $fields{$field}{optional}) {
			$Blank{$field} = qq(Required field "$field" contains no data);
			next;
		}

		## Type checking
		my $argNum = 0;
		foreach my $arg (@{ $form{$field} }) {
			$argNum++;

			## Hmm, is the field empty?
			if (length $arg > 0) {
				## Check the data to make sure it's the right type.
				## Since $arg is aliased from @values, the sub can modify the
				## actual data if it wants to (filter type check).
				unless ( $fields{$field}{type}[1]->($arg) ) {
					if (scalar @{ $form{$field} } > 1) {
						$InvalidType{$field} = qq(Invalid data type found for array field $field, indices $argNum ($fields{$field}{type}[0] expected, found "$arg"));
					} else {
						$InvalidType{$field} = qq(Invalid data type found for field $field ($fields{$field}{type}[0] expected, found "$arg"));
					}
				}
			} else {
				unless ($fields{$field}{optional}) {
					## Hmm, blank field in multi-select?  Odd if that's the case
					if (scalar @{ $form{$field} } > 1) {
						$Blank{$field} = qq(Required field "$field" contains no data in $argNum segment);
					} else {
						$Blank{$field} = qq(Required field "$field" contains no data);
					}
				}
			}
		}
		if (ref $fields{$field}{reference} eq 'ARRAY') {
			@{ $fields{$field}{reference} } = @{ $form{$field} };
		} else {
			${ $fields{$field}{reference} } = $form{$field}->[0];
		}
	}

	## Ok, did all that go well?
	if (%Missing or %Invalid or %Blank or %InvalidType) {
		$Error = join ",\n",
			values %Missing,
			values %Invalid,
			values %Blank,
			values %InvalidType;
		return;
	} else {
		return $query;
	}
}

## Default type handlers

sub CheckString {
	my $value	= shift;
	## Any non-zero length string is valid
	return 1 if (length $value > 0);
	return;
}

sub CheckWord {
	my $value	= shift;
	## Must have at least \w char
	return 1 if ($value =~ /\w/);
	return;
}

sub CheckInt {
	my $value	= shift;
	return 1 if ($value =~ /^\d+$/);
	return;
}

sub CheckFloat {
	my $value	= shift;

	## Must be in a "3.0" or "30" format
#	return 1 if ($value =~ /^\d+\.\d+$/);
	return 1 if ($value =~ /^\d+.?\d*$/);
	return;
}

sub CheckEmail {
	my $value	= shift;
	## Must look like a "standard" email address.  White space
	## is permitted on the ends though.
	return 1 if ($value =~ m/^\s*<?[^@<>]+@[^@.<>]+(?:\.[^@.<>]+)+>?\s*$/);
}

sub CheckFormData {
	my %types	= ();
	@types{@_}	= \(0 .. $#_);		# Black magic, beware...
	return GetFormData (%types);
};

1;

__END__

=head1 DESCRIPTION

Basicly a blending of the B<CGI> and B<Getopt::Long> modules, and requires the B<CGI> module
to function.

The basic concept of this module is to combine the best features of the B<CGI> and B<Getopt::Long>
modules.  The B<CGI> module is great for parsing, building, and rebuilding forms, however it
lacks any real error checking abilitys such as misspelled form input names, the data types
received from them, missing values, etc.  This however, is something that the B<Getopt::Long>
module is vary good at doing.  So, basicly this module is a layer that collects the data
using the B<CGI> module and passes it to routines to do type validation and name consistency
checks all in one clean try/catch style block.

The syntax of GetFormData() is mostly the same as the GetOptions() of B<Getopt::Long>, with a
few exceptions (namely, the handling of exceptions) .  See the B<VALUE TYPES> section
for detail of the available types, and the B<EXCEPTIONS> section for exception handling
options.  If given without a type, fields are assumed to be type ":s" (optional string),
which is normally correct.

If successful, GetFormData() returns the B<CGI> object that it used to parse the data incase
you want to use it for anything else, and undef otherwise.

If you only want to do value type and name validation, use CheckFormData() instead with
a field=type list. -See the B<SYNOPSIS> for an example.

=head1 VALUE TYPES

All types are prefixed with either a ":" or "=".

Just like in B<Getopt::Long>, the ":" prefix meens that the value is optional, but
still much match the type that is defined if it is given.  The "=" prefix meens that the
value is required for this field, and of course much match the type given.  If you just
want to make sure that some value is there but don't care about the type, use the required
string type "=s", or required word type "=w".

=over 4

=item s

String type.  Any string will do if the field is optional.  If the field is required, then
this checks to see if the value length is greater then 0.

=item w

Word type.  Value must contain at least one \w char to be valid. 
Similar to a B<s> (string) type, but oftin more useful.

=item i

Integer type. 

=item f

Real number (float) type.  Data must be in '1.2' or '12' format.

=item e

Email type.  Must look like a valid email address.  White space on either end (but
not in the middle) is permitted.

  The regex used currently is m/\s*^<?[^@<>]+@[^@.<>]+(\.[^@.<>]+)+>?\s*$/.

=item xTYPE

User defined type.  See the B<EXTENSIONS> section below.  This is where you get to make up
your own tests for this module to use.

=back

=head1 EXCEPTIONS

Exceptions are handled by returning undef, and setting one or more of five different package
global variables.  Think of them first as exception objects if you must. -They aren't, but
they kinda act like it, kinda...  We must use this method until B<Perl> ever gets a real
exception system (eval/die doesn't quite cut it here because we need more information and with
a cleaner way to access it).

The exceptions are:

=over 4

=item B<%Missing>

Contains all field names we were asked to check for, but the form didn't send us at all.  This
is not the same as a field that did get sent but had no data.  Oftin this is
from GetFormData() being given a misspelled field name, or the form being sent in
an odd manor such as an alternate 'submit' button, or just hitting the enter key
while in the last (probably only) field.

Probably code bug generated exception.  Check for typos.

=item B<%Invalid>

All fields that were B<not> asked to be checked for, but the form sent them along anyway.
Most likely these are misspelled field names in the HTML form page.

Probably code bug generated exception.  Check for typos.

=item B<%Blank>

All valid fields that were sent with no value AND the type given was set to '=' to
require the field to be filled in.  The user probably just didn't fill in the field(s) at
all.  It's not a bad practice to make all required fields in form with the word '(required)'
next to them.  Some users will try many times to fill in a form with as little information
as they can, as lame as such practice really is.

Probably a lazy user error generated exception.  Kick the lazy user.

=item B<%InvalidType>.

The type passed did not match the type asked for.  Such as the value 'foo' being sent
as the value for a field that was marked as being an integer, or 'I hate spam'
being sent as the value for an email field.

Probably a user error generated exception.  Kick the lazy user.

=item B<$CGI::Validate::Error>

End all, be all dumping ground for exceptions.  If any of the above exceptions occurs, the
B<long messages> are added here.  If any usage errors are found, they are added here.  If
the moon shifts off it's orbit, it's added here.  Use this if you just want to do a simple
one shot test like:

  GetFormData (foo => \$foo) or die "Parse error: $CGI::Validate::Error";

Think of it as my version of B<$@> if I were to throw "real" exceptions. :-)

This is also used for internal (non-data) error reporting, such as not giving me a valid reference
type to dump the data into, an unbalanced validation list, etc.

=back

The four hash exceptions have the same format.  The keys are all the fields that had
that kind of exception, and the values are much longer error messages that give further
details that can be useful for debugging.  Generally however, if you need such detail it's
much easier to just use the B<$CGI::Validate::Error> bucket that contains all of the error
messages from all of the exceptions in one place.

=head1 EXTENSIONS

User validation types can be defined using the addExtensions() function.  addExtensions()
takes a hash of extension names and code refs to use.  All extension names will automatically
have an 'x' prepended to them, so that myType would be B<x>myType.  Validation code is
expected to return true for valid types, and false/undef for invalid.  Validation code is
passed a single value of the form value.  This value is an alias to the real data
variable so "filters" can be implemented as well that actually change the data.  Some examples
for a Social Security Number checker, and an amount checker that looks for a number or the
string "max" doing a conversion of "max" to it's own max amount constant:

  my $MAX_AMOUNT = 100;

  addExtensions (
      SSNumber  => sub { $_[0] =~ /^\d{9}$/ },  # SSN must be 9 digit number
      Amount    => sub {
          if ($_[0] =~ /max/i) {
              $_[0] = $MAX_AMOUNT;  # modify value to be max amount
              return 1;
          } elsif (($_[0] =~ /^\d+$/) {
              return 1;
          } else {
              return 0;
          }
      },
  );
  GetFormData (
      'ssn=xSSNumber'   => \$ssn,
      'amount=xAmount'  => \$amount,
  );

As such, if the field "amount" were to contain the string "max", it would be auto-converted
to the value of the constant $MAX_AMOUNT (100) before being assigned to $amount so that
no further data changes or checks are needed.

All normal exception variables apply.

=head1 BUGS

Not tested much with B<mod_perl>, but it should work since each B<Apache> connection
runs in it's own space as it's own process.  Be carful to manually set your two
global config values ($CGI::Validate::Complete and $CGI::Validate::IgnoreNonMatchingFields)
however, even if you use the "default" values.  This is because as globals they will
be recycled on the next use under B<mod_perl>.

Email address can never be fully tested (see the Perl FAQ for reasons why).
The regexp I use is also pretty lame, although I use a better one in
version 1.11+.	This is mainly do to the fact that I don't use it myself,
and don't have much reason to research better methods/checks.  If you need more extensive
testing, feel free to add an extension via addExtension().

=head1 SEE ALSO

perl(1), CGI(3), mod_perl(1)

=head1 HISTORY

 $Log: Validate.pm,v $
 Revision 2.0  1998/05/28 10:24:58  byron
 	-Version handling code.
 	-Export symbol names.
 	-How we handle the CGI object data.  Towit, we do some direct internal access for speed
 	 reasons.  Yes, I'm walking into CGI.pm's house without asking, so shoot me.  CGI.pm's
 	 data access methods are so needlessly slow it isn't even funny, but to change them
 	 would break the "documented" interface.  If this proves to be a problem later, I'll probably
 	 just bypass CGI.pm alltogether and do it myself.

 Revision 1.11  1998/05/23 11:16:54  byron
 	-Changed CheckEmail regexp
 	-Better docs
 	-Probably something else...

 Revision 1.10  1998/05/13 21:37:22  byron
 	-Fixed bug from changes in the CGI module interface.

 Revision 1.9  1998/05/11 13:16:48  byron
 	-Added thankyous

 Revision 1.8  1998/05/11 13:06:32  byron
 	-Added CheckFormData()
 	-Added more docs

 Revision 1.7  1998/05/11 12:45:21  byron
 	-Doc changes

 Revision 1.6  1998/05/11 12:36:01  byron
 	-Almost everything
 	-Added user defined types

 Revision 1.5  1998/05/07 13:04:41  byron
 	-Changed float to match /^\d+.?\d*$/ so that ints are ok too

 Revision 1.4  1998/05/07 10:51:23  byron
 	-Changed CGI module access to use ReadParse for speed?
 	-Some doc changes.

 Revision 1.3  1998/03/30 12:12:09  byron
 	-Complete overhaul of the exception handling code.
 	 The old $Error code will still work the same, but there now are much
 	 cleaner ways to figure out exactly what happended and do something
 	 about it.
 	-Changed my email address to match my new account. :-)

 Revision 1.2  1997/12/19 03:46:30  byron
 	-Documentation changes/updates

=head1 AUTHOR

Zenin <zenin@archive.rhps.org>

aka Byron Brummer <byron@omix.com>

With input from Earl Hood <ehood@geneva.acs.uci.edu>, and Lloyd Zusman <ljz@asfast.com>,
and the email regex from Elijah <http://www.qz.to/~eli/>.

=head1 COPYRIGHT

Copyright (c) 1997,1998 OMIX, Inc.
All rights reserved

Use is granted under the same terms of Perl.

=cut
