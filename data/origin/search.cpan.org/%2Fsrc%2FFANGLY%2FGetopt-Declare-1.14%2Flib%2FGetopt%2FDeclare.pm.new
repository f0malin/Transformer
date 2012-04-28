package Getopt::Declare;

use strict;
use vars qw($VERSION);
use Carp;

$VERSION = '1.14';

sub import {
	my ($class, $defn) = @_;
	return if @_<2 || ! length $defn;
	$_[2] = Getopt::Declare->new($defn);
	exit(0) unless $_[2];
	delete $_[2]{_internal};
}

sub AUTOLOAD {
	use vars '$AUTOLOAD';
	return if $AUTOLOAD =~ /::DESTROY$/  ;
	$AUTOLOAD =~ s/.*::/main::/;
	goto &$AUTOLOAD;
}

package Getopt::Declare::StartOpt;

sub new        { bless {} }
sub matcher    { '(?:()' }
sub code       { '' }
sub cachecode  { '' }
sub trailer    { undef }
sub ows	       { return $_[1]; }

package Getopt::Declare::EndOpt;

sub new        { bless {} }
sub matcher    { '())?' }
sub code       { '' }
sub cachecode  { '' }
sub trailer    { undef }
sub ows        { return $_[1]; }

package Getopt::Declare::ScalarArg;

my %stdtype = ();

sub _reset_stdtype
{
	%stdtype = 
	(
		':i'	=> { pattern => '(?:(?:%T[+-]?)%D+)' },
		':n'	=> { pattern => '(?:(?:%T[+-]?)(?:%D+(?:%T\.%D*)?(?:%T[eE][+-]?%D+)?|%T\.%D+(?:%T[eE][+-]?%D+)?))' },
		':s'	=> { pattern => '(?:%T(?:\S|\0))+' },
		':qs'	=> { pattern => q{(?:"(?:\\"|[^"])*"|'(?:\\'|[^'])*'|(?:%T(?:\S|\0))+)} },
		':id'	=> { pattern => '%T[a-zA-Z_](?:%T\w)*' },
		':if'	=> { pattern => '(?:%T(?:\S|\0))+',
			     action => '{reject (!defined $_VAL_ || $_VAL_ ne "-" && ! -r $_VAL_, "in parameter \'$_PARAM_\' (file \"$_VAL_\" is not readable)")}' },
		':of'	=> { pattern => '(?:%T(?:\S|\0))+',
			     action => '{reject (!defined $_VAL_ || $_VAL_ ne "-" && -e $_VAL_ && ! -w $_VAL_ , "in parameter \'$_PARAM_\' (file \"$_VAL_\" is not writable)")}' },
		''	=> { pattern => ':s', ind => 1 },
		':+i'	=> { pattern => ':i',
			     action => '{reject (!defined $_VAL_ || $_VAL_<=0, "in parameter \'$_PARAM_\' ($_VAR_ must be an integer greater than zero)")}',
			     ind => 1},
		':+n'	=> { pattern => ':n',
			     action => '{reject (!defined $_VAL_ || $_VAL_<=0, "in parameter \'$_PARAM_\' ($_VAR_ must be a number greater than zero)")}',
			     ind => 1},
		':0+i'	=> { pattern => ':i',
			     action => '{reject (!defined $_VAL_ || $_VAL_<0, "in parameter \'$_PARAM_\' ($_VAR_ must be an positive integer)")}',
			     ind => 1},
		':0+n'	=> { pattern => ':n',
			     action => '{reject (!defined $_VAL_ || $_VAL_<0, "in parameter \'$_PARAM_\' ($_VAR_ must be a positive number)")}',
			     ind => 1},
	);
}

sub stdtype  # ($typename)
{
	my $name = shift;
	my %seen = ();
	while (!$seen{$name} && $stdtype{$name} && $stdtype{$name}->{ind})
		{
			$seen{$name} = 1;
			$name = $stdtype{$name}->{pattern}
		}

	return undef if $seen{$name} || !$stdtype{$name};
	return $stdtype{$name}->{pattern};
}

sub stdactions  # ($typename)
{
	my $name = shift;
	my %seen = ();
	my @actions = ();
	while (!$seen{$name} && $stdtype{$name} && $stdtype{$name}->{ind})
	{
		$seen{$name} = 1;
		push @actions, $stdtype{$name}->{action}
			if $stdtype{$name}->{action};
		$name = $stdtype{$name}->{pattern}
	}
	push @actions, $stdtype{$name}->{action}
		if $stdtype{$name}->{action};

	return @actions;
}

sub addtype  # ($abbrev, $pattern, $action, $ref)
{
	my $typeid = ":$_[0]";
	unless ($_[1] =~ /\S/) { $_[1] = ":s" , $_[3] = 1; }
	$stdtype{$typeid} = {};
	$stdtype{$typeid}->{pattern} = "(?:$_[1])" if $_[1] && !$_[3];
	$stdtype{$typeid}->{pattern} = ":$_[1]" if $_[1] && $_[3];
	$stdtype{$typeid}->{action} = $_[2] if $_[2];
	$stdtype{$typeid}->{ind} = $_[3];
}

sub new  # ($self, $name, $type, $nows)
{
	bless
	{	name => $_[1],
		type => $_[2],
		nows => $_[3],
	}, ref($_[0])||$_[0];
}

sub matcher  # ($self, $trailing)
{
	my ($self, $trailing) = @_;

	#WAS: $trailing = $trailing ? '(?!\Q'.$trailing.'\E)' : '';
	$trailing = $trailing ? '(?!'.quotemeta($trailing).')' : '';
	my $stdtype = stdtype($self->{type});
	if (!$stdtype && $self->{type} =~ m#\A:/([^/]+)/\Z#) { $stdtype = $1; }
	if (!$stdtype)
	{
		die "Error: bad type in Getopt::Declare parameter variable specification near '<$self->{name}$self->{type}>'\n";
	}
	$stdtype =~ s/\%D/(?:$trailing\\d)/g;
	$stdtype =~ s/\%T/$trailing/g;
	unless ($stdtype =~ s/\%F//)
	{
		$stdtype = Getopt::Declare::Arg::negflagpat().$stdtype;
	}
	$stdtype = Getopt::Declare::Arg::negflagpat().$stdtype;

	return "(?:$stdtype)";
}

sub code  # ($self, $pos, $package)
{
	my $code = '
		$_VAR_ = q|<' . $_[0]->{name} . '>|;
		$_VAL_ = defined $' . ($_[1]+1) . '? $' . ($_[1]+1) . ': undef;
		$_VAL_ =~ tr/\0/ / if $_VAL_;';

	my @actions = stdactions($_[0]->{type});
	foreach ( @actions )
	{
		s/(\s*\{)/$1 package $_[2]; /;
		$code .= "\n\t\tdo $_;";
	}

	$code .= '
		my $' . $_[0]->{name} . ' = $_VAL_;';

	return $code;
}

sub cachecode  # ($self, $ownerflag, $itemcount)
{
	return "\t\t\$self->{'$_[1]'}{'<$_[0]->{name}>'} = \$$_[0]->{name};\n"
		if $_[2] > 1;
	return "\t\t\$self->{'$_[1]'} = \$$_[0]->{name};\n";
}

sub trailer { '' }; # MEANS TRAILING PARAMETER VARIABLE

sub ows
{
	return '[\s\0]*('.$_[1].')' unless $_[0]->{nows};
	return '('.$_[1].')';
}


package Getopt::Declare::ArrayArg;

use base qw( Getopt::Declare::ScalarArg );

sub matcher  # ($self, $trailing)
{
	my ($self, $trailing) = @_;
	my $suffix = (defined $trailing && !$trailing) ? '([\s\0]+)' : '';
	my $scalar = $self->SUPER::matcher($trailing);
	return $scalar.'(?:[\s\0]+'.$scalar.')*'.$suffix;
}

sub code  # ($self, $pos, $package)
{
	my $code = '
		$_VAR_ = q|<' . $_[0]->{name} . '>|;
		$_VAL_ = undef;
		my @' . $_[0]->{name} . ' = map { tr/\0/ /; $_ } split " ", $'.($_[1]+1)."||'';\n";

	my @actions = Getopt::Declare::ScalarArg::stdactions($_[0]->{type});
	if (@actions)
	{
		$code .= '
		foreach $_VAL_ ( @' . $_[0]->{name} . ' )
		{';
		foreach ( @actions )
		{
			s/(\s*\{)/$1 package $_[2]; /;
			$code .= "\n\t\t\tdo $_;\n";
		}
		$code .= '
		}';
	}
	return $code;
}

sub cachecode  # ($self, $ownerflag, $itemcount)
{
	return "\t\t\$self->{'$_[1]'}{'<$_[0]->{name}>'} = []
			unless \$self->{'$_[1]'}{'<$_[0]->{name}>'};
		push \@{\$self->{'$_[1]'}{'<$_[0]->{name}>'}}, \@$_[0]->{name};\n"
			if $_[2] > 1;
	return "\t\t\$self->{'$_[1]'} = []
			unless \$self->{'$_[1]'};
		push \@{\$self->{'$_[1]'}}, \@$_[0]->{name};\n";
}


package Getopt::Declare::Punctuator;

sub new  # ($self, $text, $nows)
{
	bless { text => $_[1], nows => $_[2] }
}

sub matcher  # ($self, $trailing)
{
	#WAS: Getopt::Declare::Arg::negflagpat() . '\Q' . $_[0]->{text} . '\E';
	Getopt::Declare::Arg::negflagpat() . quotemeta($_[0]->{text});
}

sub code  # ($self, $pos)
{
	"
		\$_PUNCT_{'" . $_[0]->{text} . "'" . '} = $' . ($_[1]+1) . ";\n";
}

sub cachecode	# ($self, $ownerflag, $itemcount)
{
	return "\t\t\$self->{'$_[1]'}{'$_[0]->{text}'} = \$_PUNCT_{'$_[0]->{text}'};\n"
		if $_[2] > 1;
	return "\t\t\$self->{'$_[1]'} = \$_PUNCT_{'$_[0]->{text}'};\n";
}

sub trailer  { $_[0]->{text} };

sub ows
{
	return '[\s\0]*('.$_[1].')' unless $_[0]->{nows};
	return '('.$_[1].')';
}


package Getopt::Declare::Arg;

use Text::Balanced qw( extract_bracketed );

my $nextID = 0;

my @helpcmd = qw( -help --help -Help --Help -HELP --HELP -h -H );
my %helpcmd = map { $_ => 1 } @helpcmd;

sub besthelp { foreach ( @helpcmd ) { return $_ if exists $helpcmd{$_}; } }
sub helppat  { return join '|', keys %helpcmd; }

my @versioncmd = qw( -version --version -Version --Version
                     -VERSION --VERSION -v -V );
my %versioncmd = map { $_ => 1 } @versioncmd;

sub bestversion {foreach (@versioncmd) { return $_ if exists $versioncmd{$_}; }}
sub versionpat  { return join '|', keys %versioncmd; }

my @flags;
my $posflagpat = '';
my $negflagpat = '';
sub negflagpat
{
	$negflagpat = join '', map { "(?!".quotemeta($_).")" } @flags
		if !$negflagpat && @flags;
	return $negflagpat;
}

sub posflagpat
{
	$posflagpat = '(?:'.join('|', map { quotemeta($_) } @flags).')'
		if !$posflagpat && @flags;
	return $posflagpat;
}

sub new  # ($class, $spec, $desc, $dittoflag)
{
	my ($class,$spec,$desc,$ditto) = @_;
	my $first = 1;
	my $arg;
	my $nows;

	my $self =
	{
		flag 	     => '',
		flagid       => '',
		args	     => [],
		actions	     => [],
		ditto	     => $ditto,
		required     => 0,
		requires     => '',
		ID	     => $nextID++,
		desc	     => $spec,
		items	     => 0,
	};

	$self->{desc} =~ s/\A\s*(.*?)\s*\Z/$1/;

	my $ws_seen = "";

	while ($spec)
	{
		# OPTIONAL
		if ($spec =~ s/\A(\s*)\[/$1/)
		{
			push @{$self->{args}}, Getopt::Declare::StartOpt->new;
			next;
		}
		elsif ($spec =~ s/\A\s*\]//)
		{
			push @{$self->{args}}, Getopt::Declare::EndOpt->new;
			next;
		}

		# ARG
		($arg,$spec,$nows) = extract_bracketed($spec,'<>');
		if ($arg)
		{
			$arg =~ m/\A(\s*)(<)([a-zA-Z]\w*)(:[^>]+|)>/ or
				die "Error: bad Getopt::Declare parameter variable specification near '$arg'\n";

			my @details = ( $3, $4, !$first && !length($nows) );  # NAME,TYPE,NOWS

			if ($spec =~ s/\A\.\.\.//)  # ARRAY ARG
			{
				push @{$self->{args}},
					Getopt::Declare::ArrayArg->new(@details);
			}
			else  # SCALAR ARG
			{
				push @{$self->{args}},
					Getopt::Declare::ScalarArg->new(@details);
			}
			$self->{items}++;
			next;
		}

		# PUNCTUATION
		elsif ( $spec =~ s/\A(\s*)((\\.|[^] \t\n[<])+)// )
		{
			my ($ows, $punct) = ($1,$2);
			$punct =~ s/\\(?!\\)(.)/$1/g;
			if ($first) {
				$spec =~ m/\A(\S+)/;
				$self->{flagid} = $punct.($1||"");
				$self->{flag} = $punct;
				push @flags, $punct;
			}

			else	    { push @{$self->{args}},
					Getopt::Declare::Punctuator->new($punct,!length($ows));
				      $self->{items}++; }

		}

		else { last; }

	}
	continue
	{
		$first = 0;
	}

	delete $helpcmd{$self->{flag}} if exists $helpcmd{$self->{flag}};
	delete $versioncmd{$self->{flag}} if exists $versioncmd{$self->{flag}};

	bless $self;
}

sub code
{
	my ($self, $owner,$package) = @_;

	my $code = "\n";
	my $flag = $self->{flag};
	my $flagid = $self->{flagid};
	my $clump = $owner->{_internal}{clump};
	my $i = 0;
	my $nocase = (Getopt::Declare::_nocase() || $self->{nocase} ? 'i' : '');

	$code .= (!$self->{repeatable} && !$owner->{_internal}{all_rep})
			? q#	    param: while (!$_FOUND_{'# . $self->id . q#'}#
			: q#	    param: while (1#;

	if ($flag && ($clump==1 && $flag !~ /\A[^a-z0-9]+[a-z0-9]\Z/i
		  || ($clump<3 && @{$self->{args}} )))
	{
		$code .= q# && !$_lastprefix#;
	}

	$code .= q#)
	    {
		pos $_args = $_nextpos if defined $_args;
		%_PUNCT_ = ();#;

	if ($flag)
	{
		#WAS: $_args =~ m/\G[\s\0]*\Q# . $flag . q#\E/g# . $nocase
		$code .= q#
	
		$_args && $_args =~ m/\G[\s\0]*# . quotemeta($flag) . q#/g# . $nocase
		. q# or last;
		$_errormsg = q|incorrect specification of '# . $flag . q#' parameter| unless $_errormsg;

		#;
	}
	elsif ((Getopt::Declare::ScalarArg::stdtype($self->{args}[0]{type})||'') !~ /\%F/)
	{
		$code .= q#
	
		last if $_errormsg;

		#;
	}

	$code .= q#
		$_PARAM_ = '# . $self->name . q#';
		#;
	my @trailer;
	$#trailer = @{$self->{args}};
	for ($i=$#{$self->{args}} ; $i>0 ; $i-- )
	{
		$trailer[$i-1] = $self->{args}[$i]->trailer();
		$trailer[$i-1] = $trailer[$i] unless defined $trailer[$i-1];
	}

	if (@{$self->{args}})
	{
		$code .= "\t\t".'$_args && $_args =~ m/\G';
		for ($i=0; $i < @{$self->{args}} ; $i++ )
		{
		    $code .= $self->{args}[$i]->ows($self->{args}[$i]->matcher($trailer[$i]));
		}
		$code .= '/gx' . $nocase . ' or last;'
	}


	for ($i=0; $i < @{$self->{args}} ; $i++ )
	{
		$code .= $self->{args}[$i]->code($i,$package);	#, $flag ????
	}

	if ($flag)
	{
	    $code .= q#
		if (exists $_invalid{'# . $flag . q#'})
		{
			$_errormsg = q|parameter '# . $flag
				  . q#' not allowed with parameter '|
				  . $_invalid{'# . $flag . q#'} . q|'|;
			last;
		}
		else
		{
			foreach (#
			. ($owner->{_internal}{mutex}{$flag}
			    ? join(',', map {"'$_'"} @{$owner->{_internal}{mutex}{$flag}})
			    : '()')
			. q#)
			{
				$_invalid{$_} = '# . $flag . q#';
			}
		}
		#
	}

	foreach my $action ( @{$self->{actions}} )
	{
		$action =~ s{(\s*\{)}
			    { $1 package $package; };
		$code .= "\n\t\tdo " . $action . ";\n";
	}

	if ($flag && $self->{items}==0)
	{
		$code .= "\n\t\t\$self->{'$flag'} = '$flag';\n";
	}
	foreach my $subarg ( @{$self->{args}} )
	{
		$code .= $subarg->cachecode($self->name,$self->{items});
	}

	if ($flag =~ /\A([^a-z0-9]+)/i)	{ $code .= '$_lastprefix = "'.quotemeta($1).'";'."\n" }
	else				{ $code .= '$_lastprefix = "";' }

	$code .= q#
		$_FOUND_{'# . $self->name . q#'} = 1;
		next arg if pos $_args;
		$_nextpos = length $_args;
		last arg;
	}

		  #;
}

sub name {
	my $self = shift;
	return $self->{flag} || "<$self->{args}[0]{name}>";
}

sub id {
	my $self = shift;
	return $self->{flagid} || "<$self->{args}[0]{name}>";
}


package Getopt::Declare;

use Text::Balanced qw( :ALL );
use Text::Tabs	   qw( expand );

# PREDEFINED GRAMMARS

my %_predef_grammar = 
(
	"-PERL" =>
q{	-<varname:id>		Set $<varname> to 1 [repeatable]
				{ no strict "refs"; ${"::$varname"} = 1 }

},
			
	"-AWK" =>
q{	<varname:id>=<val>	Set $<varname> to <val> [repeatable]
				{no strict "refs";  ${"::$varname"} = $val }
  	<varname:id>=		Set $<varname> to '' [repeatable]
				{no strict "refs";  ${"::$varname"} = '' }

},
);
my $_predef_grammar = join '|', keys %_predef_grammar;

sub _quoteat
{
	my $text = shift;
	$text =~ s/\A\@/\\\@/;
	$text =~ s/([^\\])\@/$1\\\@/;
	$text;
}

sub new  # ($self, $grammar; $source)
{
	# HANDLE SHORT-CIRCUITS
	return 0 if @_==3 && (!defined($_[2]) || $_[2] eq '-SKIP'); 

	# SET-UP
	my ($_class, $_grammar) = @_;

	# PREDEFINED GRAMMAR?
	if ($_grammar =~ /\A(-[A-Z]+)+/)
	{
		my $predef = $_grammar;
		my %seen = ();
		$_grammar = '';
		$predef =~ s{($_predef_grammar)}{ do {$_grammar .= $_predef_grammar{$1} unless $seen{$1}; $seen{$1} = 1; ""} }ge;
		return undef if $predef || !$_grammar;
	}

	# PRESERVE ESCAPED '['s (opening bracket only)
	$_grammar =~ s/\\\[/\255/g;

	# MAKE SURE GRAMMAR ENDS WITH A NEWLINE
	$_grammar =~ s/([^\n])\Z/$1\n/;

	# SET-UP
	local $_ = $_grammar;
	my @_args = ();
	my $_mutex = {};
	my $_action;
	my $_strict = 0;
	my $_all_repeatable = 0;
	my $_lastdesc = undef;
	_nocase(0);
	Getopt::Declare::ScalarArg::_reset_stdtype();

	# CONSTRUCT GRAMMAR
	while (length $_ > 0)
	{
		# COMMENT:
		s/\A[ 	]*#.*\n// and next;

		# TYPE DIRECTIVE:
		s{\A(\s*\[\s*pvtype:\s*\S+\s+)/}{$1 qr/};
		if (m/\A\s*\[\s*pvtype:/ and $_action = extract_codeblock($_,'[]'))
		{
			$_action =~ s/.*?\[\s*pvtype:\s*//;
			_typedef($_action);
			next;
		}

		# ACTION
		if ($_action = extract_codeblock)
		{
			# WAS: eval q{no strict;my $ref = sub }._quoteat($_action).q{;1}
			my $_check_action = $_action;
			$_check_action =~ s{(\s*\{)}
			    { $1 sub defer(&); sub finish(;\$); sub reject(;\$\$); };
			eval q{no strict;my $ref = sub }.$_check_action.q{;1}
			   or die "Error: bad action in Getopt::Declare specification:"
				. "\n\n$_action\n\n$@\n";
			if ($#_args < 0)
			{
				die "Error: unattached action in Getopt::Declare specification:\n$_action\n"
				    . "\t(did you forget the tab after the preceding parameter specification?)\n"
			}
			push @{$_args[$#_args]->{actions}}, $_action;
			next;
		}
		elsif (m/\A(\s*[{].*)/)
		{
			die "Error: incomplete action in Getopt::Declare specification:\n$1.....\n" 
			    . "\t(did you forget a closing '}'?)\n";
		}

		# ARG + DESC:
		if ( s/\A(.*?\S.*?)(\t.*\n)// )
		{
			my $spec = $1;
			my $desc = $2;
			my $ditto;
			$_strict ||= $desc =~ /\Q[strict]/;

			$desc .= $1 while s/\A((?![ 	]*({|\n)|.*?\S.*?\t.*?\S).*?\S.*\n)//;
			
			$_lastdesc and $desc =~ s/\A\s*\[\s*ditto\s*\]/$_lastdesc/
				  and $ditto = 1;
			$_lastdesc = $desc;

			my $arg = Getopt::Declare::Arg->new($spec,$desc,$ditto) ;
			push @_args, $arg;

			_infer($desc, $arg, $_mutex);
			next;
		}


		# OTHERWISE: DECORATION
		s/((?:(?!\[\s*pvtype:).)*)(\n|(?=\[\s*pvtype:))//;
		my $decorator = $1;
		$_strict ||= $decorator =~ /\Q[strict]/;
		_infer($decorator, undef, $_mutex);
		$_all_repeatable = 1 if $decorator =~ /\[\s*repeatable\s*\]/;
	}

	my $_lastactions;
	foreach ( @_args )
	{
		if ($_lastactions && $_->{ditto} && !@{$_->{actions}})
			{ $_->{actions} = $_lastactions }
		else
			{ $_lastactions = $_->{actions} }
	}

	@_args = sort
	{
		length($b->{flag}) <=> length($a->{flag})
				   or
 	  $b->{flag} eq $a->{flag} and $#{$b->{args}} <=> $#{$a->{args}}
				   or
		          $a->{ID} <=> $b->{ID}

	} @_args;

	# CONSTRUCT OBJECT ITSELF
	my $clump = ($_grammar =~ /\[\s*cluster:\s*none\s*\]/i)     ? 0
		  : ($_grammar =~ /\[\s*cluster:\s*singles?\s*\]/i) ? 1
		  : ($_grammar =~ /\[\s*cluster:\s*flags?\s*\]/i)   ? 2
		  : ($_grammar =~ /\[\s*cluster:\s*any\s*\]/i)      ? 3
		  : ($_grammar =~ /\[\s*cluster:(.*)\s*\]/i)  	 ?
			die "Error: unknown clustering mode: [cluster:$1]\n"
		  :						   3;

	my $self = bless
	{
		_internal =>
		{
			args	=> [@_args],
			mutex	=> $_mutex,
			usage	=> $_grammar,
			helppat => Getopt::Declare::Arg::helppat(),
			verspat => Getopt::Declare::Arg::versionpat(),
			strict	=> $_strict,
			clump	=> $clump,
			source  => '',
			all_rep => $_all_repeatable,
			'caller'  => scalar caller(),
		}
	}, ref($_class)||$_class;


	# VESTIGAL DEBUGGING CODE
	open (CODE, ">.CODE")
		and print CODE $self->code($self->{_internal}{'caller'})
		and close CODE
			if $::Declare_debug;

	# DO THE PARSE (IF APPROPRIATE)
	if (@_==3) { return undef unless defined $self->parse($_[2]) }
	else	   { return undef unless defined $self->parse(); }

	return $self;
}

sub _get_nextline { scalar <> }

sub _load_sources  # ( \$_get_nextline, @files )
{
	my $text  = '';
	my @found = ();
	my $gnlref = shift;
	foreach ( @_ )
	{
		open FILE, $_ or next;
		if (-t FILE)
		{
			push @found, '<STDIN>';
			$$gnlref = \&_get_nextline;
		}
		else
		{
			push @found, $_;
			$text .= join "\n", <FILE>;
		}
	}
	return undef unless @found;
	$text = <STDIN> unless $text;
	return ( $text, join(" or ",@found));
}


sub parse  # ($self;$source)
{
	my ( $self, $source ) = @_;
	my $_args = ();
	my $_get_nextline = sub { undef };
	if (@_>1) # if $source was provided
	{
		if (!defined $source)
		{
			return 0;
		}
		elsif ( ref $source eq 'CODE' )
		{
			$_get_nextline = $source;
			$_args = &{$_get_nextline}($self);
			$source = '[SUB]';
		}
		elsif ( ref $source eq 'GLOB' )
		{
			if (-t *$source)
			{
				$_get_nextline = \&_get_nextline ;
				$_args = <STDIN>;
				$source = '<STDIN>';
			}
			else
			{
				$_args = join ' ', (<$source>);
				$_args =~ tr/\t\n/ /s;
				$source = ref($source);
			}
		}
		elsif ( ref $source eq 'IO::Handle' )
		{
			if (!($source->fileno) && -t)
			{
				$_get_nextline = \&_get_nextline ;
				$_args = <STDIN>;
				$source = '<STDIN>';
			}
			else
			{
				$_args = join ' ', (<$source>);
				$_args =~ tr/\t\n/ /s;
				$source = ref($source);
			}
		}
		elsif ( ref $source eq 'ARRAY' )
		{
			if (@$source == 1 && (!defined($source->[0])
					      || $source->[0] eq '-BUILD'
				              || $source->[0] eq '-SKIP') )
			{
				return 0;
			}
			elsif (@$source == 1 && $source->[0] eq '-STDIN')
			{
				$_get_nextline = \&_get_nextline ;
				$_args = <STDIN>;
				$source = '<STDIN>';
			}
			elsif (@$source == 1 && $source->[0] eq '-CONFIG')
			{
				my $progname = "$0rc";
				$progname =~ s#.*/##;
				($_args,$source) = _load_sources(\$_get_nextline,"$ENV{HOME}/.$progname", ".$progname");
			}
			else
			{
				my $stdin;
				($_args,$source) = _load_sources(\$_get_nextline,@$source);
			}
		}
		else  # LITERAL STRING TO PARSE
		{
			$_args = $source;
			substr($source,7) = '...' if length($source)>7;
			$source = "\"$source\"";
		}
		return 0 unless defined $_args;
		$source = " (in $source)";
	}
	else  # $source was NOT provided
	{
		foreach (@ARGV) {
			# Clean entries: remove spaces, tabs and newlines
			$_ =~ tr/ \t\n/\0\0\0/;
		}
		$_args = join(' ', @ARGV);
		$source = '';
	}

	$self->{_internal}{source} = $source;

	if (!eval $self->code($self->{_internal}{'caller'}))
	{
		die "Error: in generated parser code:\n$@\n" if $@;
		return undef;
	}

	return 1;
}

sub type  # ($abbrev, $pattern, $action)
{
	&Getopt::Declare::ScalarArg::addtype;
}

sub _enbool
{
	my $expr = shift;
	$expr =~ s/\s*\|\|\s*/ or /g;
	$expr =~ s/\s*&&\s*/ and /g;
	$expr =~ s/\s*!\s*/ not /g;
	return $expr;
}

sub _enfound
{
	my $expr = shift;
	my $original = $expr;
	$expr =~ s/((?:&&|\|\|)?\s*(?:[!(]\s*)*)([^ \t\n|&\)]+)/$1\$_FOUND_{'$2'}/gx;
	die "Error: bad condition in [requires: $original]\n"
		unless eval 'no strict; my $ref = sub { '.$expr.' }; 1';
	return $expr;
}

my $_nocase = 0;

sub _nocase
{
	$_nocase = $_[0] if $_[0];
	return $_nocase;
}

sub _infer  # ($desc, $arg, $mutex)
{
	my ($desc, $arg, $mutex) = @_;

	_mutex($mutex, split(' ',$1))
		while $desc =~ s/\[\s*mutex:\s*(.*?)\]//i;

	if ( $desc =~ m/\[\s*no\s*case\s*\]/i)
	{
		if ($arg) { $arg->{nocase} = 1 }
		else	  { _nocase(1); }
	}

	if (defined $arg)
	{
		_exclude($mutex, $arg->name, (split(' ',$1)))
			if $desc =~ m/.*\[\s*excludes:\s*(.*?)\]/i;
		$arg->{requires} = $1
			if $desc =~ m/.*\[\s*requires:\s*(.*?)\]/i;

		$arg->{required}   = ( $desc =~ m/\[\s*required\s*\]/i );
		$arg->{repeatable} ||= ( $desc =~ m/\[\s*repeatable\s*\]/i );
	}

	_typedef($desc) while $desc =~ s/.*?\[\s*pvtype:\s*//;
}

sub _typedef
{
	my $desc = $_[0];
	my ($name,$pat,$action,$ind);

	($name,$desc) = (extract_quotelike($desc))[5,1];
	do { $desc =~ s/\A\s*([^] \t\n]+)// and $name = $1 } unless $name;
	die "Error: bad type directive (missing type name): [pvtype: "
	   . substr($desc,0,index($desc,']')||20). "....\n"
		unless $name;

	($pat,$desc,$ind) = (extract_quotelike($desc,'\s*:?\s*'))[5,1,2];
	do { $desc =~ s/\A\s*(:?)\s*([^] \t\n]+)//
		and $pat = $2 and $ind = $1 } unless $pat;
	$pat = '' unless $pat;
	$action = extract_codeblock($desc) || '';

	die "Error: bad type directive (expected closing ']' but found"
	    . "'$1' instead): [pvtype: $name " . ($pat?"/$pat/":'')
	    . " $action $1$2....\n" if $desc =~ /\A\s*([^] \t\n])(\S*)/;

	Getopt::Declare::ScalarArg::addtype($name,$pat,$action,$ind=~/:/);
}

sub _ditto  # ($originalflag, $orginaldesc, $extra)
{
	my ($originalflag, $originaldesc, $extra) = @_;
	if ($originaldesc =~ /\n.*\n/)
	{
		$originaldesc = "Same as $originalflag ";
	}
	else
	{
		chomp $originaldesc;
		$originaldesc =~ s/\S/"/g;
		1 while $originaldesc =~ s/"("+)"/ $1 /g;
		$originaldesc =~ s/""/" /g;
	}
	return "$originaldesc$extra\n";
}

sub _mutex  # (\%mutex, @list)
{
	my ($mref, @mutexlist) = @_;

	foreach my $flag ( @mutexlist )
	{
		$mref->{$flag} = [] unless $mref->{$flag};
		foreach my $otherflag ( @mutexlist )
		{
			next if ($flag eq $otherflag);
			push @{$mref->{$flag}}, $otherflag;
		}
	}
}

sub _exclude  # (\%mutex, $excluded, @list)
{
	my ($mref, $excluded, @mutexlist) = @_;

	foreach my $flag ( @mutexlist )
	{
		unless ($flag eq $excluded)
		{
			$mref->{$flag} = [] unless $mref->{$flag};
			push @{$mref->{$excluded}}, $flag;
			push @{$mref->{$flag}}, $excluded;
		}
	}
}

sub version
{
	my ($self, $exit_status) = @_;
	# my $filedate = localtime(time - 86400 * -M $0);
	my $filedate = localtime((stat $0)[9]);
	if ($::VERSION) { print "\n\t$0: version $::VERSION  ($filedate)\n\n" }
	else { print "\n\t$0: version dated $filedate\n\n" }
	exit $exit_status if defined $exit_status;
	return 1;
}

sub usage
{
	my ($self, $exit_status) = @_;

        my $use_pager = eval { require IO::Pager };

	if ($use_pager)
	{
		new IO::Pager; # use a pager for all print() statements
	}

	print $self->usage_string;

	if ($use_pager)
	{
		close; # done using the pager
	}

	if (defined $exit_status)
	{
		exit $exit_status;
	}
	return 1;
}

sub usage_string
{
	my $self = shift;

	local $_ = $self->{_internal}{usage};

	my $lastflag = undef;
	my $lastdesc = undef;

	my $usage = '';
	my $uoff;
	my $decfirst;
	my $ditto;

	while (length $_ > 0)
	{

		# COMMENT:
		s/\A[ 	]*#.*\n// and next;

		# TYPE DIRECTIVE:
		#WAS: if (m/\A\s*\[\s*pvtype:/ and extract_codeblock($_,'[{}]'))
		if (m/\A\s*\[\s*pvtype:/ and extract_bracketed($_,'[{}]'))
		{
			next;
		}

		# ACTION
		#WAS: extract_codeblock and do {
		extract_bracketed($_,'[{}]') and do {
			s/\A[ 	]*\n//;
			$decfirst = 0 unless defined $decfirst;
			next;
		};

		# ARG + DESC:
		if ( s/\A(.*?\S.*?\t+)(.*?\n)// )
		{
			$decfirst = 0 unless defined $decfirst;

			my ($spec) = expand $1;
			my ($desc) = expand $2;

			$desc .= (expand $1)[0]
				while s/\A((?![ 	]*({|\n)|.*?\S.*?\t.*?\S).*?\S.*\n)//;

			# Skip parameters with the special directive [undocumented]
			next if $desc =~ /\[\s*undocumented\s*\]/i;

			$uoff = 0;
			$spec =~ s/(<[a-zA-Z]\w*):([^>]+)>/$uoff+=1+length $2 and "$1>"/ge;

			$ditto = $desc =~ /\A\s*\[\s*ditto\s*\]/;
			$desc =~ s/^\s*\[.*?\]\s*\n//gm;
			$desc =~ s/\[.*?\]//g;

			if ($ditto)
				{ $desc = ($lastdesc? _ditto($lastflag,$lastdesc,$desc) : "" ) }
			elsif ($desc =~ /\A\s*\Z/)
				# Skip parameters with no description
				{ next; }
			else
				{ $lastdesc = $desc; }
			$spec =~ /\A\s*(\S+)/ and $lastflag = $1;

			$usage .= $spec . ' ' x $uoff . $desc;

			next;
		};

		# OTHERWISE, DECORATION
		if (s/((?:(?!\[\s*pvtype:).)*)(\n|(?=\[\s*pvtype:))//)
		{
			my $desc = $1.($2||'');
			$desc =~ s/^(\s*\[.*?\])+\s*\n//gm;
			$desc =~ s/\[.*?\]//g;
			$decfirst = 1 unless defined $decfirst
						or $desc =~ m/\A\s*\Z/;
			$usage .= $desc;
			next;
		}

		# Should never get here if all goes well
		die "Error: internal error\n";
	}

	my $required = '';

	foreach my $arg ( @{$self->{_internal}{args}} )
	{
		if ($arg->{required})
		{
			$required .= ' ' . $arg->{desc} . ' ';
		}
	}

	# REINSTATE ESCAPED '['s
	$usage =~ s/\255/[/g;  

	$required =~ s/<([a-zA-Z]\w*):[^>]+>/<$1>/g;

	my $helpcmd = Getopt::Declare::Arg::besthelp;
	my $versioncmd = Getopt::Declare::Arg::bestversion;

	my $msg = '';
	unless ($self->{_internal}{source})
	{
		$msg .= "\nUsage: $0 [options] $required\n";
		$msg .= "       $0 $helpcmd\n" if $helpcmd;
		$msg .= "       $0 $versioncmd\n" if $versioncmd;
		$msg .= "\n" unless $decfirst && $usage =~ /\A[ \t]*\n/;
	}
	$msg .= "Options:\n" unless $decfirst;
	$msg .= $usage;
	return $msg;
}

sub unused {
	return @{$_[0]->{_internal}{unused}} if wantarray;
	return join " ", @{$_[0]->{_internal}{unused}};
}

sub flatten {
	my ($val, $nested) = @_;
	if (ref $val eq 'ARRAY') {
		return join " ", map {flatten($_,1)} @$val;
	}
	elsif (ref $val eq 'HASH') {
		return join " ", map {
				$nested || /^-/ ? ($_, flatten($val->{$_},1))
				                : (flatten($val->{$_},1))
			} keys %$val;
	}
	else {
		return $val;
	}
}

sub used {
	my $self = shift;
	my @used = map { /^_/ ? () : ($_, $self->{$_}) } keys %$self;
	return @used if wantarray;
	return join " ", map { flatten $_ } @used;
}

sub code
{
	my $self = shift;
	my $package = shift||'main';

	my $code = q#

	do
	{
	  my @_deferred = ();
	  my @_unused = ();
	  sub # . $package . q#::defer (&);
	  {
	    package # . $package . q#; local $^W;
	    *defer = sub (&) { push @_deferred, $_[0]; }
	  }
	  my %_FOUND_ = ();
	  my $_errors = 0;
	  my $_nextpos;
	  my %_invalid = ();
	  my $_lastprefix = '';
	  my $_finished = 0;
	  my %_PUNCT_;
	  my $_errormsg;
	  my $_VAL_;
	  my $_VAR_;
	  my $_PARAM_;

	  sub # . $package . q#::reject (;$$);
	  sub # . $package . q#::finish (;$);

	  {
	    package # . $package . q#; local $^W; 
	    *reject = sub (;$$) { local $^W; if (!@_ || $_[0]) { $_errormsg = $_[1] if defined $_[1]; last param; } };
	    *finish = sub (;$) { if (!@_ || $_[0]) { $_finished = 1; } };
	  }

	  $_nextpos = 0;
	  arg: while (!$_finished)
	  {
		$_errormsg = '';
		# . ( $self->{_internal}{clump} ? q#
		while ($_lastprefix)
		{
			my $substr = substr($_args,$_nextpos);
			$substr =~ m/\A(?!\s|\0|\Z)#
				. Getopt::Declare::Arg::negflagpat() . q#/
				or do { $_lastprefix='';last};
			"$_lastprefix$substr" =~ m/\A(#
				.  Getopt::Declare::Arg::posflagpat()
				. q#)/
				or do { $_lastprefix='';last};
			substr($_args,$_nextpos,0) = $_lastprefix;
			last;
		}
		# : '') . q#
		pos $_args = $_nextpos if defined $_args;

		$self->usage(0) if $_args && $_args =~ m/\G(# . $self->{_internal}{helppat} . q#)(\s|\0|\Z)/g;
		$self->version(0) if $_args && $_args =~ m/\G(# . $self->{_internal}{verspat} . q#)(\s|\0|\Z)/g;

	#;

	foreach my $arg ( @{$self->{_internal}{args}} )
	{
		$code .= $arg->code($self,$package);
	}

	$code .= q#

	  if ($_lastprefix)
	  {
		  pos $_args = $_nextpos+length($_lastprefix);
		  $_lastprefix = '';
		  next;
	  }
	
	  pos $_args = $_nextpos;
	  $_args && $_args =~ m/\G[\s\0]*(\S+)/g or last;
	  if ($_errormsg) { print STDERR "Error"."$self->{_internal}{source}: $_errormsg\n" }

	  else { push @_unused, $1; }
	  $_errors++ if ($_errormsg);
	  }
	  continue
	  {
		$_nextpos = pos $_args if defined $_args;
		if (defined $_args and $_args =~ m/\G[\s\0]*\Z/g)
		{
			$_args = &{$_get_nextline}($self);
			last unless defined($_args);
			$_nextpos = 0;
			$_lastprefix = '';
		}
	  }
	  #;

	foreach my $arg ( @{$self->{_internal}{args}} )
	{
		next unless $arg->{required};
		$code .= q#
	  do { print STDERR "Error"."$self->{_internal}{source}".': required parameter # . $arg->name . q# not found.',"\n"; $_errors++ }
		unless $_FOUND_{'# . $arg->name . q#'}#;
		if ($self->{_internal}{mutex}{$arg->name})
		{
			foreach my $mutex (@{$self->{_internal}{mutex}{$arg->name}})
			{
				$code .= q# or $_FOUND_{'# . $mutex . q#'}#;
			}
		}
		$code .= ';';
	}
	
	foreach my $arg ( @{$self->{_internal}{args}} )
	{
		if ($arg->{requires})
		{
			$code .= q#
	  do { print STDERR q|Error|.$self->{_internal}{source}.q|: parameter '# . $arg->name
		  . q#' can only be specified with '# . _enbool($arg->{requires})
		  . q#'|,"\n"; $_errors++ }
		if $_FOUND_{'# . $arg->name . "'} && !(" . _enfound($arg->{requires}) . ');'
		}
	}

	$code .= q#
		push @_unused, split(' ', substr($_args,$_nextpos))
			if $_args && $_nextpos && length($_args) >= $_nextpos;
		#;

	if ($self->{_internal}{strict})
	{
		$code .= q#
		unless ($_nextpos < length($_args||''))
		{
			foreach (@_unused)
			{
				tr/\0/ /;
				print STDERR "Error"."$self->{_internal}{source}: unrecognizable argument ('$_')\n";
				$_errors++;
			}
		}
		#
	}

	$code .= q#

	  if ($_errors && !$self->{_internal}{source})
	  {
		print STDERR "\n(try '$0 ".'# . Getopt::Declare::Arg::besthelp
				. q#'."' for more information)\n";
	  }

	  $self->{_internal}{unused} = [map { tr/\0/ /; $_ } @_unused];
	  @ARGV = @{$self->{_internal}{unused}}
		unless $self->{_internal}{source};

	  unless ($_errors) { foreach (@_deferred) { &$_ } }

	  !$_errors;

	}
	#;

}

1;
__END__

=head1 NAME

Getopt::Declare - Declaratively Expressed Command-Line Arguments via Regular Expressions

=head1 VERSION

This document describes version 1.14 of Getopt::Declare

=head1 SYNOPSIS

 use Getopt::Declare;

 $args = Getopt::Declare->new($specification_string, $optional_source);

 # or:

 use Getopt::Declare $specification_string => $args;


=head1 DESCRIPTION

=head2 Overview

F<Getopt::Declare> is I<yet another> command-line argument parser,
one which is specifically designed to be powerful but exceptionally
easy to use.

To parse the command-line in C<@ARGV>, one simply creates a
F<Getopt::Declare> object, by passing C<Getopt::Declare::new()> a
specification of the various parameters that may be encountered:

	use Getopt::Declare;
	$args = Getopt::Declare->new($specification);

This may also be done in a one-liner:

	use Getopt::Declare, $specification => $args;

The specification is a single string such as this:

	$specification = q(

		-a		Process all data

		-b <N:n>	Set mean byte length threshold to <N>
					{ bytelen = $N; }

		+c <FILE>	Create new file <FILE>

		--del 		Delete old file
					{ delold() }

		delete 		[ditto]

		e <H:i>x<W:i>	Expand image to height <H> and width <W>
					{ expand($H,$W); }

		-F <file>...	Process named file(s)
					{ defer {for (@file) {process()}} }

		=getrand [<N>]	Get a random number
				(or, optionally, <N> of them)
					{ $N = 1 unless defined $N; }

		--		Traditionally indicates end of arguments
					{ finish }
	);

B<Note that in each of the cases above, there is a tab between each
parameter definition and description (even if you can't see it)!>
In the specification, the syntax of each parameter is declared,
along with a description and (optionally) one or more actions to
be performed when the parameter is encountered. The specification
string may also include other usage formatting information (such
as group headings or separators) as well as standard Perl comments
(which are ignored).

Calling C<Getopt::Delare::new()> parses the contents of the array C<@ARGV>,
extracting any arguments which match the parameters defined in the
specification string, and storing the parsed values as hash elements
within the new F<Getopt::Declare> object being created.

Other features of the F<Getopt::Declare> package include:

=over 4

=item *

The use of full Perl regular expressions to constrain matching
of parameter components.

=item *

Automatic generation of error, usage and version information.

=item *

Optional conditional execution of embedded actions (i.e. only on
successful parsing of the entire command-line)

=item *

Strict or non-strict parsing (unrecognized command-line elements may either
trigger an error or may simply be left in C<@ARGV>)

=item *

Declarative specification of various inter-parameter relationships (for
example, two parameters may be declared mutually exclusive and this
relationship will then be automatically enforced).

=item *

Intelligent clustering of adjacent flags (for example: the
command-line sequence "S<-a -b -c>" may be abbreviated to "-abc", unless
there is also a C<-abc> flag declared).

=item *

Selective or global case-insensitivity of parameters.

=item *

The ability to parse files (especially configuration files) instead of
the command-line.

=back

=head2 Terminology

The terminology of command-line processing is often confusing, with various
terms (such as "argument", "parameter", "option", "flag", etc.)
frequently being used interchangeably and inconsistently in the various
F<Getopt::> packages available. In this documentation, the following
terms are used consistently: 

=over 4

=item "command-line"

The space-separated concatenation of the elements of the array C<@ARGV>
at the time a F<Getopt::Declare> object is created.

=item "parameter specification" (or just "parameter")

A specification of a single entity which may appear in the
command-line. Always includes at least one syntax for the entity.
Optionally may include other (I<variant>) syntaxes, one or more
I<descriptions> of the entity, and/or I<actions> to be performed when
the entity is encountered. For example, the following is a single
parameter specification (with two variants):

    --window <height> x <width>	    Set window to <height> by <width>
					{ setwin($width,$height); }

    --window <h>x<w>@<x>,<y>	    Set window size and centroid
					{ setwin($w,$h,$x,$y); }


=item "argument"

A substring of the command-line which matches a single parameter variant.
Unlike some other Getopt:: packages, in F<Getopt::Declare> an argument
may be a single element of C<@ARGV>, or part of a single C<@ARGV> element,
or the concatenation of several adjacent C<@ARGV> elements.


=item "parameter definition"

A specification of one actual syntax variant matched by a parameter. Always
consists of a leading I<parameter flag> or I<parameter variable>,
optionally followed by one or more I<parameter components> (that is,
other parameter variables or I<punctuators>). In the above example, 
C<S<--window E<lt>heightE<gt> x E<lt>widthE<gt>>> is a parameter definition.


=item "parameter flag" (or just "flag")

A sequence of non-space characters which introduces a parameter. Traditionally
a parameter flag begins with "-" or "--", but F<Getopt::Declare> allows
almost any sequence of characters to be used as a flag. In the above example,
C<--window> is the parameter flag.


=item "parameter variable"

A place-holder (within a parameter specification) for a value that 
will appear in any argument matching that parameter. In the above example,
C<E<lt>heightE<gt>>, C<E<lt>widthE<gt>>, C<E<lt>hE<gt>>, C<E<lt>yE<gt>>,
C<E<lt>xE<gt>>, and C<E<lt>yE<gt>> are all parameter variables.


=item "parameter punctuator" (or just "punctuator")

A literal sequence of characters (within a parameter specification)
which will appear in any argument matching that parameter. In the above
example, the literals C<x> and C<@> are punctuators.


=item "parameter description"

A textual description of the purpose and/or use of a particular variant of
parameter. In the above examples, the string:

	Set window to <height> by <width>
	
is a parameter description.


=item "parameter action" (or just "action")

A block of Perl code to be executed in response to encountering a specific
parameter. In the above example:

	{ setwin($width,$height); }

is a parameter action.

=item "parameter variants"

One or more different syntaxes for a single parameter, all sharing
the same leading flag, but having different trailing parameter
variables and/or punctuators. F<Getopt::Declare> considers all parameter
definitions with the same leading flag to be merely variant forms of
a single "underlying" parameter. The above example shows two parameter
variants for the C<--window> parameter.

=back


=head2 Parameter definitions

As indicated above, a parameter specification consists of three
parts: the parameter definition, a textual description, and any
actions to be performed when the parameter is matched.

The parameter definition consists of a leading flag or parameter
variable, followed by any number of parameter variables or
punctuators, optionally separated by spaces. The parameter definition
is terminated by the first tab that is encountered after the start
of the parameter definition.  At least one trailing tab I<must> be present.

For example, all of the following are valid F<Getopt::Declare> parameter
definitions:

	-v				
	in=<infile>			
	+range <from>..<to>		
	--lines <start> - <stop>	
	ignore bad lines		
	<outfile>				

B<Note that each of the above examples has at least one trailing tab
(even if you can't see them)!>. Note too that this hodge-podge of
parameter styles is certainly not recommended within a single program,
but is shown so as to illustrate some of the range of parameter syntax
conventions F<Getopt::Declare> supports.

The spaces between components of the parameter definition are optional but
significant, both in the definition itself and in the arguments that
the definition may match. If there is no space between components in the
specification, then no space is allowed between corresponding arguments
on the command-line. If there I<is> space between components of the
specification, then space between those components is optional on the
command-line.

For example, the C<--lines> parameter above matches:

	--lines1-10
	--lines 1-10
	--lines 1 -10
	--lines 1 - 10
	--lines1- 10

If it were instead specified as:

	--lines <start>-<stop>	

then it would match only:

	--lines1-10
	--lines 1-10

Note that the optional nature of spaces in parameter specification implies that
flags and punctuators cannot contain the character '<' (which is taken as the
delimiter for a parameter variable) nor the character '[' (which
introduces an optional parameter component - see
L<"Optional parameter components">).


=head2 Types of parameter variables

By default, a parameter variable will match a single blank-terminated
or comma-delimited string. For example, the parameter:

	-val <value>	

would match any of the following arguments:

	-value			# <value> <- "ue"
	-val abcd		# <value> <- "abcd"
	-val 1234		# <value> <- "1234"
	-val "a value"		# <value> <- "a value"


It is also possible to restrict the types of values which may be
matched by a given parameter variable. For example:

	-limit <threshold:n>	Set threshold to some (real) value
	-count <N:i>		Set count to <N> (must be an integer)

If a parameter variable is suffixed with ":n", it will match any
reasonable numeric value, whilst the ":i" suffix restricts a
parameter variable to only matching integer values. 
These two "type specifiers" are the simplest examples of a much more
powerful mechanism, which allows parameter variables to be restricted
to matching any specific regular expression. See L<"Defining new
parameter variable types">.

Parameter variables are treated as scalars by default, but this too
can be altered. Any parameter variable immediately followed by
an ellipsis (C<...>) is treated as a list variable, and matches its
specified type sequentially as many times as possible. For example,
the parameter specification:

	-pages <page:i>...	

would match either of the following arguments:

	-pages 1
	-pages 1 2 7 20

Note that both scalar and list parameter variables are "respectful" of the
flags of other parameters as well as their own trailing punctuators.
For example, given the specifications:

	-a			
	-b <b_list>...		
	-c <c_list>... ;	

The following arguments will be parsed as indicated:

	-b -d -e -a		# <b_list>  <-  ("-d", "-e")
	-b -d ; 		# <b_list>  <-  ("-d", ";")
	-c -d ;			# <c_list>  <-  ("-d")

List parameter variables are also "repectful" of the needs of
subsequent parameter variables. That is, a parameter specification
like:

	-copy <files>... <dir>	

will behave as expected, putting all but the last string after the C<-copy>
flag into the parameter variable C<E<lt>filesE<gt>>, whilst the very
last string is assigned to C<E<lt>dirE<gt>>.


=head2 Optional parameter components

Except for the leading flag, any part of a parameter definition
may be made optional by placing it in square brackets.
For example:

	+range <from> [..] [<to>]

which matches any of:

	+range 1..10
	+range 1..
	+range 1 10
	+range 1

List parameter variables may also be made optional (the ellipsis must
follow the parameter variable name immediately, so it goes I<inside>
the square brackets):

	-list [<page>...]

Two or more parameter components may be made jointly optional, by specifying
them in the same pair of brackets. Optional components may also be nested. For
example:

	-range <from> [.. [<to>] ]

Scalar optional parameter variables (such as C<[E<lt>toE<gt>]>)
are given undefined values if they are skipped during
a successful parameter match. List optional parameter variables (such as
C<[E<lt>pageE<gt>...]>) are assigned an empty list if unmatched.

One important use for optional punctuators is to provide abbreviated
versions of specific flags. For example:

	-num[eric]		# Match "-num" or "-numeric"
	-lexic[ographic]al	# Match "-lexical" or "-lexicographical"
	-b[ells+]w[histles]	# Match "-bw" or "-bells+whistles"

Note that the actual flags for these three parameters are C<-num>, C<-lexic>
and C<-b>, respectively.

=head2 Parameter descriptions

Providing a textual description for each parameter (or parameter
variant) is optional, but strongly recommended. Apart from providing internal
documentation, parameter descriptions are used in the automatically-generated
usage information provided by F<Getopt::Declare>.

Descriptions may be placed after the first tab(s) following the
parameter definition and may be continued on subsequent lines,
provided those lines do not contain any tabs after the first
non-whitespace character (because any such line will instead be
treated as a new parameter specification). The description is
terminated by a blank line, an action specification (see below) or
another parameter specification.

For example:

	-v				Verbose mode
	in=<infile>			Specify input file
					(will fail if file does not exist)

	+range <from>..<to>		Specify range of columns to consider
	--lines <start> - <stop>	Specify range of lines to process

	ignore bad lines		Ignore bad lines :-)

	<outfile>			Specify an output file

The parameter description may also contain special directives which
alter the way in which the parameter is parsed. See the various
subsections of L<"ADVANCED FEATURES"> for more information.

A common mistake is to use tabs to separate components of a parameter
description:

	-delete	<filename>		Delete the named file
	-d	<filename>		Delete the named file

The tabs after C<"-delete"> and C<"-d"> do a good job of lining up the
two C<"<filenameE<gt>"> parameter variables, but they also mark the 
start of the description, which means that after descriptions are
stripped, the two parameters are:

	-delete
	-d

The solution is to use spaces, not tabs, to align components within a
parameter specification.

=head2 Actions

Each parameter specification may also include one or more blocks of
Perl code, specified in a pair of curly brackets (which I<must> start on
a new line).

Each action is executed as soon as the corresponding parameter is
successfully matched in the command-line (but see L<"Deferred actions">
for a means of delaying this response).

For example:

        -v      Verbose mode
                        { $::verbose = 1; }
        -q      Quiet mode
                        { $::verbose = 0; }

Actions are executed (as C<do> blocks) in the package in which the
F<Getopt::Declare> object containing them was created. Hence they
have access to all package variables and functions in that namespace.

In addition, each parameter variable belonging to the corresponding
parameter is made available as a (block-scoped) Perl variable with the
same name. For example:

        +range <from>..<to>     Set range
                                        { setrange($from, $to); }

        -list <page:i>...       Specify pages to list
                                        { foreach (@page)
                                          {
                                                list($_) if $_ > 0;
                                          }
                                        }

Note that scalar parameter variables become scalar Perl variables,
and list parameter variables become Perl arrays.


=head2 Predefined variables available in actions

Within an action the following variables are also available:

=over 4

=item C<$_PARAM_>

Stores the identifier of the current parameter: either the leading
flag or, if there is no leading flag, the name of the first parameter
variable.


=item C<%_PUNCT_>

Stores the substring matched by each punctuator in the current parameter.
The hash is indexed by the punctuator itself. The main purpose of this variable
is to allow actions to check whether optional punctuators were in fact matched.
For example:

        -v[erbose]      Set verbose mode
                        (doubly verbose if full word used)
                            { if ($_PUNCT_{"erbose"}) { $verbose = 2; }
                              else                    { $verbose = 1; }
                            }

=item C<%_FOUND_>

This hash stores boolean values indicating whether or not a given
parameter has already been found. The hash keys are the leading flags
or parameter variables of each parameter. For instance, the following
specification makes the C<-q> and C<-v> parameters mutually exclusive
(but see L<"Parameter dependencies"> for a I<much> easier way to achieve
this effect):

        -v      Set verbose mode
                        { die "Can't be verbose *and* quiet!\n"
                                if $_FOUND_{"-q"};
                        }

        -q      Set quiet mode
                        { die "Can't be quiet *and* verbose!\n"
                                if $_FOUND_{"-v"};
                        }

For reasons that will be explained in L<"Rejection and termination">,
a given parameter is not marked as found until I<after> its
associated actions are executed. That is, C<$_FOUND_{$_PARAM_}> will not
(usually) be true during a parameter action.

=back

Note that, although numerous other internal variables on which the
generated parser relies are also visible within parameter actions,
accessing any of them may have Dire Consequences. Moreover, these
other variables may no longer be accessible (or even present) in
future versions of F<Getopt::Declare>. All such internal variables
have names beginning with an underscore. Avoiding such variables names
will ensure there are no conflicts between actions and the parser
itself.


=head2 The command-line parsing process

Whenever a F<Getopt::Declare> object is created, the current command-line
is parsed sequentially, by attempting to match each parameter
in the object's specification string against the current elements in the
C<@ARGV> array (but see L<"Parsing from other sources">). The order
in which parameters are compared against the arguments in C<@ARGV>
is determined by three rules:

=over 4

=item 1.

Parameters with longer flags are tried first. Hence the command-line
argument "-quiet" would be parsed as matching the parameter C<-quiet>
rather than the parameter C<S<-q E<lt>stringE<gt>>>, even if the C<-q>
parameter was defined first.

=item 2.

Parameter I<variants> with the most components are
matched first. Hence the argument "-rand 12345" would be parsed as matching
the parameter variant C<S<-rand E<lt>seedE<gt>>>, rather than the
variant C<-rand>, even if the "shorter" C<-rand> variant was defined first.

=item 3.

Otherwise, parameters are matched in the order they are defined.

=back

Note, however, that the I<arguments> themselves are considered strictly
in the order they appear on the command line. That is: Getopt::Declare
takes the first (leftmost) argument and compares it against all the
parameter specifications in the order described above. Then it gets the
second argument and does the same. Et cetera. So, whilst parameters are
considered "flags-first-by-length", arguments are considered
"left-to-right". If that seems paradoxical, you probably need to review
the difference between "arguments" and "parameters", as explained
in L<"Terminology">.

Elements of C<@ARGV> which do not match any defined parameter are collected
during the parse and are eventually put back into C<@ARGV>
(see L<"Strict and non-strict command-line parsing">).


=head1 ADVANCED FEATURES

=head2 Case-insensitive parameter matching

By default, a F<Getopt::Declare> object parses the command-line in
a I<case-sensitive> manner. The C<[nocase]> directive enables a specific
parameter (or, alternatively, I<all> parameters) to be matched
case-insensitively.

If a C<[nocase]> directive is included in the description of a
specific parameter variant, then that variant (only) will be matched
without regard for case. For example, the specification:

        -q      Quiet mode [nocase]

        -v      Verbose mode

means that the arguments "S<-q>" and "S<-Q>" will both match the C<-q> parameter, but
that only "S<-v>" (and I<not> "S<-V>") will match the C<-v> parameter.

If a C<[nocase]> directive appears anywhere I<outside> a parameter description,
then the entire specification is declared case-insensitive and all parameters
defined in that specification are matched without regard to case.


=head2 Termination and rejection

It is sometimes useful to be able to terminate command-line
processing before all arguments have been parsed. To this end,
F<Getopt::Declare> provides a special local operator (C<finish>) which
may be used within actions. The C<finish> operator takes a single optional
argument. If the argument is true (or omitted),
command-line processing is terminated at once (although the current
parameter is still marked as having been successfully matched). For
example:

        --      Traditional argument list terminator
                        { finish }

        -no--   Use non-traditional terminator instead
                        { $nontrad = 1; }

        ##      Non-traditional terminator (only valid if -no-- flag seen)
                        { finish($nontrad); }

It is also possible to reject a single parameter match from within an
action (and then continue trying other candidates). This allows
actions to be used to perform more sophisticated tests on the type of
a parameter variable, or to implement complicated parameter
interdependencies.

To reject a parameter match, the C<reject> operator is used. The
C<reject> operator takes an optional argument.
If the argument is true (or was omitted), the current parameter
match is immediately rejected. For example:

        -ar <R:n>       Set aspect ratio (must be in the range (0..1])
                                {
                                  $::sawaspect++;
                                  reject $R <= 0 || $R > 1 ;
                                  setaspect($R);
                                }

        -q              Quiet option (not available on Wednesdays)
                                {
                                  reject((localtime)[6] == 3);
                                  $::verbose = 0;
                                }

Note that any actions performed I<before> the call to C<reject> will
still have effect (for example, the variable C<$::sawaspect> remains
incremented even if the aspect ratio parameter is subsequently rejected).

The C<reject> operator may also take a second argument, which is
used as an error message if the rejected argument subsequently
fails to match any other parameter. For example:

        -q      Quiet option (not available on Wednesdays)
                        {
                          reject((localtime)[6] == 3 => "Not today!");
                          $::verbose = 0;
                        }


=head2 Specifying other parameter variable types

As was mentioned in L<"Type of parameter variables">, parameter
variables can be restricted to matching only numbers or only integers
by using the type specifiers ":n" and ":i". F<Getopt::Declare>
provides seven other inbuilt type specifiers, as well as two mechanisms
for defining new restrictions on parameter variables.

The other inbuilt type specifiers are:

=over 4

=item :+i

which restricts a parameter variable to matching positive, non-zero
integers (that is: 1, 2, 3, etc.)

=item :+n

which restricts a parameter variable to matching positive, non-zero
numbers (that is, floating point numbers strictly greater than zero).

=item :0+i 

which restricts a parameter variable to matching non-negative integers (that
is: 0, 1, 2, 3, etc.)

=item :0+n

which restricts a parameter variable to matching non-negative numbers (that
is, floating point numbers greater than or equal to zero).

=item :qs

which allows a parameter variable to match any quote-delimited or
whitespace-terminated string. Note that this specifier simply makes
explicit the default behaviour.

=item :id

which allows a parameter variable to match any identifier
sequence. That is: a alphabetic or underscore, followed by
zero-or-more alphanumerics or underscores.

=item :if

which is used to match input file names. Like type ':s', type ':if'
matches any quote-delimited or whitespace-terminated string. However
this type does I<not> respect other command-line flags and also
requires that the matched string is either "-" (indicating standard
input) or the name of a readable file.

=item :of

which is used to match output file names. It is exactly like type ':if' except
that it requires that the string is either "-" (indicating standard output)
or the name of a file that is either writable or non-existent.

=item :s

which allows a parameter variable to match any quote-delimited or
whitespace-terminated string. Note that this specifier simply makes
explicit the default behaviour.

=back

For example:

        -repeat <count:+i>      Repeat <count> times (must be > 0)

        -scale <factor:0+n>     Set scaling factor (cannot be negative)


Alternatively, parameter variables can be restricted to matching a
specific regular expression, by providing the required pattern
explicitly (in matched "/" delimiters after the ":"). For example:

        -parity <p:/even|odd|both/>     Set parity (<p> must be "even",
                                        "odd" or "both")

        -file <name:/\w*\.[A-Z]{3}/>    File name must have a three-
                                        capital-letter extension

If an explicit regular expression is used, there are three "convenience"
extensions available:

=over 4

=item %T

If the sequence C<%T> appears in a pattern, it is translated to a negative
lookahead containing the parameter variable's trailing context.
Hence the parameter definition:

        -find <what:/(%T\.)+/> ;

ensures that the command line argument "-find abcd;" causes C<E<lt>whatE<gt>>
to match "abcd", I<not> "abcd;".


=item %D

If the sequence C<%D> appears in a pattern, it is translated into a subpattern
which matches any single digit (like a C<\d>), but only if that digit
would I<not> match the parameter variable's trailing context.
Hence C<%D> is just a convenient short-hand for C<(?:%T\d)> (and is actually
implemented that way).

=item %F

By default, any explicit pattern is modified by F<Getopt::Declare>
so that it fails if the argument being matched represents some defined
parameter flag. If however the sequence C<%F> appears anywhere in a
pattern, it causes the pattern I<not> to reject strings which would
otherwise match another flag. By default, no inbuilt type allows
arguments to match a flag.

=back

=head2 Defining new parameter variable types

Explicit regular expressions are very powerful, but also cumbersome to
use (or reuse) in some situations. F<Getopt::Declare> provides a general
"parameter variable type definition" mechanism to simplify such cases.

To declare a new parameter variable type, the C<[pvtype:...]> directive
is used. A C<[pvtype...]> directive specifies the name, matching
pattern, and action for the new parameter variable type (though both
the pattern and action are optional).

The name string may be I<any> whitespace-terminated sequence of
characters which does not include a ">". The name may also be specified
within a pair of quotation marks (single or double) or within any 
Perl quotelike operation. For example:

        [pvtype: num     ]      # Makes this valid: -count <N:num>
        [pvtype: 'a num' ]      # Makes this valid: -count <N:a num>
        [pvtype: q{nbr}  ]      # Makes this valid: -count <N:nbr>

The pattern is used in initial matching of the parameter variable.
Patterns are normally specified as a "/.../"-delimited Perl regular
expression:

        [pvtype: num      /\d+/          ]        
        [pvtype: 'a num'  /\d+(?:\.\d*)/ ]
        [pvtype: q{nbr}   /[+-]?\d+/     ]

Note that the regular expression should I<not> contain any capturing 
parentheses, as this will interfere with the correct processing of
subsequent parameter variables.

Alternatively the pattern associated with a new type may be specified
as a ":" followed by the name of another parameter variable type (in
quotes if necessary). In this case the new type matches the same
pattern (and action! - see below) as the named type.  For example:

        [pvtype: num      :+i      ]    # <X:num> is the same as <X:+i>
        [pvtype: 'a num'  :n       ]    # <X:a num> is the same as <X:n>
        [pvtype: q{nbr}   :'a num' ]    # <X:nbr> is also the same as <X:n>

As a third alternative, the pattern may be omitted altogether, in
which case the new type matches whatever the inbuilt pattern ":s"
matches.

The optional action which may be included in any C<[pvtype:...]>
directive is executed I<after> the corresponding parameter variable
matches the command line but I<before> any actions belonging to the
enclosing parameter are executed. Typically, such type actions
will call the C<reject> operator (see L<"Termination and rejection">)
to test extra conditions, but any valid Perl code is acceptable. For
example:

        [pvtype: num    /\d+/    { reject if (localtime)[6]==3 }      ]
        [pvtype: 'a num'  :n       { print "a num!" }           ]
        [pvtype: q{nbr}   :'a num' { reject $::no_nbr }         ]

If a new type is defined in terms of another (for example, ":a num"
and ":nbr" above), any action specified by that new type is
I<prepended> to the action of that other type. Hence:

=over 4

=item *

the new type ":num" matches any string of digits, but then rejects the
match if it's Wednesday.

=item *

the new type ":a num" matches any string of digits (like its parent
type ":num"), I<then> prints out "a num!", I<and then> rejects the
match if it's Wednesday (like its parent type ":num").

=item *

the new type ":nbr" matches any string of digits (like its parent type
":a num"), but then rejects the match if the global C<$::no_nbr> variable
is true. Otherwise it next prints out "a num!" (like its parent type
":a num"), and finally rejects the match if it's Wednesday (like its
grandparent type ":num").

=back

When a type action is executed (as part of a particular parameter
match), three local variables are available:

=over 4

=item C<$_VAL_>

which contains the value matched by the type's pattern. It is this value which
is ultimately assigned to the local Perl variable which is available to
parameter actions. Hence if the type action changes the value of C<$_VAL_>,
that changed value becomes the "real" value of the corresponding parameter
variable (see the Roman numeral example below).

=item C<$_VAR_>

which contains the name of the parameter variable being matched.

=item C<$_PARAM_>

which contains the name of the parameter currently being matched.

=back

Here is a example of the use of these variables:

	$specs = q{
        [pvtype: type  /[OAB]|AB')/                                     ]
        [pvtype: Rh?   /Rh[+-]/                                         ]
        [pvtype: days  :+i  { reject $_VAL_<14 " $_PARAM_ (too soon!)"} ]

          -donated <D:days>               Days since last donation
          -applied <A:days>               Days since applied to donate

          -blood <type:type> [<rh:Rh?>]   Specify blood type
                                          and (optionally) rhesus factor
        };
        $args = Getopt::Declare->new($specs);

In the above example, the ":days" parameter variable type is defined
to match whatever the ":+i" type matches (that is positive, non-zero
integers), with the proviso that the matching value (C<$_VAL_>) must
be at least 14. If a shorter value is specified for C<E<lt>DE<gt>>,
or C<E<lt>AE<gt>> parameter variables, then F<Getopt::Declare> would
issue the following (respective) error messages:

        Error: -donated (too soon!)
        Error: -applied (too soon!)

Note that the "inbuilt" parameter variable types ("i", "n", etc.) are
really just predefined type names, and hence can be altered if necessary:

        $args = Getopt::Declare->new(<<'EOPARAM');

        [pvtype: 'n' /[MDCLXVI]+/ { reject !($_VAL_=to_roman $_VAL_) } ]

                -index <number:n>       Index number
                        { print $data[$number]; }
        EOPARAM

The above C<[pvtype:...]> directive means that all parameter variables
specified with a type ":n" henceforth only match valid Roman
numerals, but that any such numerals are I<automatically> converted to
ordinary numbers (by passing C<$_VAL_>) through the C<to_roman>
function).

Hence the requirement that all ":n" numbers now must be Roman can be
imposed I<transparently>, at least as far as the actual parameter
variables which use the ":n" type are concerned. Thus C<$number> can
be still used to index the array C<@data> despite the new restrictions
placed upon it by the redefinition of type ":n".

Note too that, because the ":+n" and ":0+n" types are implicitly 
defined in terms of the original ":n" type (as if the directives:

        [pvtype: '+n'  :n { reject if $_VAL <= 0  }  ]
        [pvtype: '0+n' :n { reject if $_VAL < 0   }  ]

were included in every specification), the above redefinition of ":n"
affects those types as well. In such cases the format conversion is
performed I<before> the "sign" tests (in other words, the "inherited"
actions are performed I<after> any newly defined ones).

Parameter variable type definitions may appear anywhere in a
F<Getopt::Declare> specification and are effective for the entire
scope of the specification. In particular, new parameter variable
types may be defined I<after> they are used.

=head2 Undocumented parameters

If a parameter description is omitted, or consists entirely of
whitespace, or contains the special directive C<[undocumented]>, then
the parameter is still parsed as normal, but will not appear in the
automatically generated usage information (see L<"Usage information">).

Apart from allowing for "secret" parameters (a dubious benefit), this
feature enables the programmer to specify some undocumented action
which is to be taken on encountering an otherwise unknown argument.
For example:

        <unknown>       
                        { handle_unknown($unknown); }


=head2 "Dittoed" parameters

Sometimes it is desirable to provide two or more alternate flags for
the same behaviour (typically, a short form and a long form). To
reduce the burden of specifying such pairs, the special directive
C<[ditto]> is provided. If the description of a parameter I<begins> with
a C<[ditto]> directive, that directive is replaced with the
description for the immediately preceding parameter (including any
other directives). For example:

        -v              Verbose mode
        --verbose       [ditto] (long form)

In the automatically generated usage information this would be displayed as:

        -v              Verbose mode
        --verbose          "     "   (long form)

Furthermore, if the "dittoed" parameter has no action(s) specified, the
action(s) of the preceding parameter are reused. For example, the
specification:

        -v              Verbose mode
                                { $::verbose = 1; }
        --verbose       [ditto]

would result in the C<--verbose> option setting C<$::verbose> just like the
C<-v> option. On the other hand, the specification:

        -v              Verbose mode
                                { $::verbose = 1; }
        --verbose       [ditto]
                                { $::verbose = 2; }

would give separate actions to each flag.


=head2 Deferred actions

It is often desirable or necessary to defer actions taken in response
to particular flags until the entire command-line has been parsed. The most
obvious case is where modifier flags must be able to be specified I<after>
the command-line arguments they modify.

To support this, F<Getopt::Declare> provides a local operator (C<defer>) which
delays the execution of a particular action until the command-line processing
is finished. The C<defer> operator takes a single block, the execution of which
is deferred until the command-line is fully and successfully parsed. If
command-line processing I<fails> for some reason (see L<"DIAGNOSTICS">), the
deferred blocks are never executed.

For example:

        <files>...      Files to be processed
                            { defer { foreach (@files) { proc($_); } } }

        -rev[erse]      Process in reverse order
                            { $::ordered = -1; }

        -rand[om]       Process in random order
                            { $::ordered = 0; }

With the above specification, the C<-rev> and/or C<-rand> flags can be
specified I<after> the list of files, but still affect the processing of
those files. Moreover, if the command-line parsing fails for some reason
(perhaps due to an unrecognized argument), the deferred processing will
not be performed.


=head2 Flag clustering

Like some other F<Getopt::> packages, F<Getopt::Declare> allows parameter
flags to be "clustered". That is, if two or more flags have the same
"flag prefix" (one or more leading non-whitespace, non-alphanumeric characters),
those flags may be concatenated behind a single copy of that flag prefix.
For example, given the parameter specifications:

        -+              Swap signs
        -a              Append mode
        -b              Bitwise compare
        -c <FILE>       Create new file
        +del            Delete old file
        +e <NICE:i>     Execute (at specified nice level) when complete

The following command-lines (amongst others) are all exactly equivalent:

        -a -b -c newfile +e20 +del
        -abc newfile +dele20
        -abcnewfile+dele20
        -abcnewfile +e 20del

The last two alternatives are correctly parsed because
F<Getopt::Declare> allows flag clustering at I<any point> where the
remainder of the command-line being processed starts with a
non-whitespace character and where the remaining substring would not
otherwise immediately match a parameter flag.

Hence the trailing "+dele20" in the third command-line example is parsed as
S<"+del +e20"> and not S<"-+ del +e20">. This is because the previous "-"
prefix is I<not> propagated (since the leading "+del" I<is> a valid flag).

In contrast, the trailing S<"+e 20del"> in the fourth example is parsed as
S<"+e 20 +del"> because, after the S<" 20"> is parsed (as the integer
parameter variable C<E<lt>NICEE<gt>>), the next characters are "del",
which I<do not> form a flag themselves unless prefixed with the
controlling "+".

In some circumstances a clustered sequence of flags on the command-line
might also match a single (multicharacter) parameter flag. For example, given
the specifications:

        -a              Blood type is A
        -b              Blood type is B
        -ab             Blood type is AB
        -ba             Donor has a Bachelor of Arts

A command-line argument "-aba" might be parsed as
S<"-a -b -a"> or S<"-a -ba"> or S<"-ab -a">. In all such
cases, F<Getopt::Declare> prefers the longest unmatched flag first.
Hence the previous example would be parsed as S<"-ab -a">, unless
the C<-ab> flag had already appeared in the command-line (in which
case, it would be parsed as S<"-a -ba">).

These rules are designed to produce consistency and "least surprise",
but (as the above example illustrates) may not always do so. If the
idea of unconstrained flag clustering is too libertarian for a particular
application, the feature may be restricted (or removed completely),
by including a C<[cluster:...]> directive anywhere in the specification string.

The options are:

=over 8

=item C<[cluster: any]>

This version of the directive allows any flag to be clustered (that is,
it merely makes explicit the default behaviour).

=item C<[cluster: flags]>

This version of the directive restricts clustering to parameters which are
"pure" flags (that is, those which have no parameter variables or punctuators).

=item C<[cluster: singles]>

This version of the directive restricts clustering to parameters which are
"pure" flags, and which consist of a flag prefix followed by a single
alphanumeric character.

=item C<[cluster: none]>

This version of the directive turns off clustering completely.

=back

For example:

        $args = Getopt::Declare->new(<<'EOSPEC');
                -a              Append mode
                -b              Back-up mode
                -bu             [ditto]
                -c <file>       Copy mode
                -d [<file>]     Delete mode
                -e[xec]         Execute mode

                [cluster:singles]
        EOSPEC

In the above example, only the C<-a> and C<-b> parameters may be clustered.
The C<-bu> parameter is excluded because it consists of more than one
letter, whilst the C<-c> and C<-d> parameters are excluded because they
take (or may take, in C<-d>'s case) a variable. The C<-e[xec]> parameter
is excluded because it may take a trailing punctuator (C<[xec]>).

By comparison, if the directive had been C<[cluster: flags]>, then
C<-bu> I<could> be clustered, though C<-c>, C<-d> and C<-e[xec]> would
still be excluded since they are not "pure flags").


=head2 Strict and non-strict command-line parsing

"Strictness" in F<Getopt::Declare> refers to the way in which unrecognized
command-line arguments are handled. By default, F<Getopt::Declare> is
"non-strict", in that it simply skips silently over any unrecognized
command-line argument, leaving it in C<@ARGV> at the conclusion of
command-line processing (but only if they were originally parsed
from C<@ARGV>).

No matter where they came from, the remaining arguments are also available
by calling the C<unused> method on the Getopt::Declare object, after it
has parsed. In a list context, this method returns a list of the
unprocessed arguments; in a scalar context a single string with the unused
arguments concatenated is returned.

Likewise, there is a C<used> method that returns the arguments that were
successfully processed by the parser.

However, if a new F<Getopt::Declare> object is created with a
specification string containing the C<[strict]> directive (at any
point in the specification):

        $args = Getopt::Declare->new(<<'EOSPEC');

                [strict]

                -a      Append mode
                -b      Back-up mode
                -c      Copy mode
        EOSPEC

then the command-line is parsed "strictly". In this case, any
unrecognized argument causes an error message (see L<"DIAGNOSTICS">) to
be written to STDERR, and command-line processing to (eventually)
fail. On such a failure, the call to C<Getopt::Declare::new()> returns
C<undef> instead of the usual hash reference.

The only concession that "strict" mode makes to the unknown is that,
if command-line processing is prematurely terminated via the
C<finish> operator, any command-line arguments which have not yet
been examined are left in C<@ARGV> and do not cause the parse to fail (of
course, if any unknown arguments were encountered I<before> the
C<finish> was executed, those earlier arguments I<will> cause
command-line processing to fail).

The "strict" option is useful when I<all> possible parameters
can be specified in a single F<Getopt::Declare> object, whereas the
"non-strict" approach is needed when unrecognized arguments are either
to be quietly tolerated, or processed at a later point (possibly in a
second F<Getopt::Declare> object).


=head2 Parameter dependencies

F<Getopt::Declare> provides five other directives which modify the
behaviour of the command-line parser in some way. One or more of these
directives may be included in any parameter description. In addition,
the C<[mutex:...]> directive may also appear in any usage "decoration"
(see L<"Usage information">).

Each directive specifies a particular set of conditions that a
command-line must fulfil (for example, that certain parameters may not
appear on the same command-line). If any such condition is violated,
an appropriate error message is printed (see L<"DIAGNOSTICS">).
Furthermore, once the command-line is completely parsed, if any
condition was violated, the program terminates
(whilst still inside C<Getopt::Declare::new()>).

The directives are:

=over 4

=item C<[required]>

Specifies that an argument matching at least one variant of the
corresponding parameter I<must> be specified somewhere in the
command-line. That is, if two or more required parameters share the
same flag, it suffices that I<any one> of them matches an argument
(recall that F<Getopt::Declare> considers all parameter specifications
with the same flag merely to be variant forms of a single "underlying"
parameter).

If an argument matching a "required" flag is I<not> found in the
command-line, an error message to that effect is issued,
command-line processing fails, and C<Getopt::Declare::new()> returns
C<undef>.


=item C<[repeatable]>

By default, F<Getopt::Declare> objects allow each of their parameters to
be matched only once (that is, once any variant of a particular
parameter matches an argument, I<all> variants of that same parameter
are subsequently excluded from further consideration when parsing the
rest of the command-line).

However, it is sometimes useful to allow a particular parameter to match
more than once.  Any parameter whose description includes the directive
C<[repeatable]> is I<never> excluded as a potential argument match, no matter
how many times it has matched previously:

        -nice           Increase nice value (linearly if repeated)
                        [repeatable]
                                { set_nice( get_nice()+1 ); }

        -w              Toggle warnings [repeatable] for the rest
                        of the command-line 
                                { $warn = !$warn; }

As a more general mechanism is a C<[repeatable]> directive appears in a
specification anywhere other than a flag's description, then I<all> parameters
are marked repeatable:

        [repeatable]

        -nice           Increase nice value (linearly if repeated)
                                { set_nice( get_nice()+1 ); }

        -w              Toggle warnings for the rest of the command-line 
                                { $warn = !$warn; }


=item C<[mutex: E<lt>flag listE<gt>]>

The C<[mutex:...]> directive specifies that the parameters whose
flags it lists are mutually exclusive. That is, no two or more of them
may appear in the same command-line. For example:

        -case           set to all lower case
        -CASE           SET TO ALL UPPER CASE
        -Case           Set to sentence case
        -CaSe           SeT tO "RAnSom nOTe" CasE

                        [mutex: -case -CASE -Case -CaSe]

The interaction of the C<[mutex:...]> and C<[required]> directives is
potentially awkward in the case where two "required" arguments are
also mutually exclusive (since the C<[required]> directives insist
that both parameters must appear in the command-line, whilst the
C<[mutex:...]> directive expressly forbids this).

F<Getopt::Declare> resolves such contradictory constraints by
relaxing the meaning of "required" slightly. If a flag is marked
"required", it is considered "found" for the purposes of error
checking if it or I<any other flag with which it is mutually
exclusive> appears on the command-line. 

Hence the specifications:

        -case           set to all lower case      [required]
        -CASE           SET TO ALL UPPER CASE      [required]
        -Case           Set to sentence case       [required]
        -CaSe           SeT tO "RAnSom nOTe" CasE  [required]

                        [mutex: -case -CASE -Case -CaSe]

mean that I<exactly one> of these four flags must appear on the
command-line, but that the presence of any one of them will suffice
to satisfy the "requiredness" of all four.

It should also be noted that mutual exclusion is only tested for
I<after> a parameter has been completely matched (that is, after the
execution of its actions, if any). This prevents "rejected" parameters
(see L<"Termination and rejection">) from incorrectly generating
mutual exclusion errors. However, it also sometimes makes it necessary
to defer the actions of a pair of mutually exclusive parameters (for
example, if those actions are expensive or irreversible).


=item C<[excludes: E<lt>flag listE<gt>]>

The C<[excludes:...]> directive provides a "pairwise" version of
mutual exclusion, specifying that the current parameter is mutually exclusive
with all the other parameters lists, but those other parameters are not
mutually exclusive with each other. That is, whereas the specification:

        -left           Justify to left margin
        -right          Justify to right margin
        -centre         Centre each line

        [mutex: -left -right -centre]

means that only one of these three justification alternatives can ever be used
at once, the specification:

        -left           Justify to left margin   
        -right          Justify to right margin 
        -centre         Centre each line  [excludes: -left -right]

means that C<-left> and C<-right> can still be used together
(probably to indicate "left I<and> right" justification), but that
neither can be used with C<-centre>. Note that the C<[excludes:...]>
directive also differs from the C<[mutex:...]> in that it is always 
connected with a paricular parameter, I<implicitly>
using the flag of that parameter as the target of exclusion.


=item C<[requires: E<lt>conditionE<gt>]>

The C<[requires]> directive specifies a set of flags which
must also appear in order for a particular flag to be permitted in the
command-line. The condition is a boolean expression, in which the
terms are the flags or various parameters, and the operations are 
C<&&>, C<||>, C<!>, and bracketting. For example, the specifications:

        -num            Use numeric sort order
        -lex            Use "dictionary" sort order
        -len            Sort on length of line (or field)

        -field <N:+i>   Sort on value of field <N> 

        -rev            Reverse sort order
                        [requires: -num || -lex || !(-len && -field)]

means that the C<-rev> flag is allowed only if either the C<-num> or the
C<-lex> parameter has been used, or if it is not true that
I<both> the C<-len> I<and> the C<-field> parameters have been used.

Note that the operators C<&&>, C<||>, and C<!> retain their normal
Perl precedences.

=back

=head2 Parsing from other sources

F<Getopt::Declare> normally parses the contents of C<@ARGV>, but can
be made to parse specified files instead. To accommodate this, 
C<Getopt::Declare::new()> takes an optional second parameter, which specifies
a file to be parsed. The parameter may be either:

=over 8

=item A C<IO::Handle> reference or a filehandle GLOB reference

in which case C<Getopt::Declare::new()> reads the corresponding handle until
end-of-file, and parses the resulting text (even if it is an empty string).

=item An ARRAY reference containing the single string C<'-CONFIG'>

in which case C<Getopt::Declare::new()> looks for the files
F<$ENV{HOME}/.${progname}rc> and F<$ENV{PWD}/.${progname}rc>,
concatenates their contents, and parses that.

If neither file is found (or if both are inaccessible)
C<Getopt::Declare::new()> immediately returns zero. If a
file is found but the parse subsequently fails, C<undef> is returned.

=item An ARRAY reference containing the single string C<'-BUILD'>

in which case C<Getopt::Declare::new()> builds a parser from the
supplied grammar and returns a reference to it, but does not parse anything.
See L<"The Getopt::Declare::code() method"> and 
L<"The Getopt::Declare::parse() method">.

=item An ARRAY reference containing the single string C<'-SKIP'> or the single value C<undef> or nothing

in which case C<Getopt::Declare::new()> immediately returns zero.
This alternative is useful when using a C<FileHandle>:

        my $args = Getopt::Declare->new($grammar, new FileHandle ($filename) || -SKIP);

because it makes explicit what happens if C<FileHandle::new()> fails. Of course,
if the C<-SKIP> alternative were omitted, <Getopt::Declare::new> would
still return immediately, having found C<undef> as its second argument.

=item Any other ARRAY reference

in which case C<Getopt::Declare::new()> treats the array elements as a
list of filenames, concatenates the contents of those files, and parses that.

If the list does not denote any accessible file(s)
C<Getopt::Declare::new()> immediately returns zero. If matching files
are found, but not successfully parsed, C<undef> is returned.

=item A string

in which case C<Getopt::Declare::new()> parses that string directly.

=back

Note that when C<Getopt::Declare::new()> parses from a
source other than C<@ARGV>, unrecognized arguments are I<not>
placed back in C<@ARGV>.


=head2 Using F<Getopt::Declare> objects after command-line processing

After command-line processing is completed, the object returned by
C<Getopt::Declare::new()> will have the following features:

=over 4

=item Parameter data

For each successfully matched parameter, the F<Getopt::Declare> object
will contain a hash element. The key of that element will be the leading flag
or parameter variable name of the parameter.

The value of the element will be a reference to another hash which contains
the names and values of each distinct parameter variable and/or
punctuator which was matched by the parameter. Punctuators generate
string values containing the actual text matched. Scalar parameter
variables generate scalar values. List parameter variables
generate array references.

As a special case, if a parameter consists of a single component
(either a single flag or a single parameter variable), then the value for the
corresponding hash key is not a hash reference, but the actual value matched.

The following example illustrates the various possibilities:

        $args = Getopt::Declare->new( q{

                -v <value> [etc]        One or more values
                <infile>                Input file [required]
                -o <outfiles>...        Output files
        } );

        if ( $args->{'-v'} )
        {
                print  "Using value: ", $args->{'-v'}{'<value>'};
                print  " (et cetera)" if $args->{'-v'}{'etc'};
                print  "\n";
        }

        open INFILE, $args->{'<infile>'} or die;
        @data = <INFILE>;

        foreach $outfile ( @{$args->{'-o'}{'<outfiles>'}} )
        {
                open  OUTFILE, ">$outfile"  or die;
                print OUTFILE process(@data);
                close OUTFILE;
        }


The values which are assigned to the various hash elements are copied from
the corresponding blocked-scoped variables which are available within
actions. In particular, if the value of any of those block-scoped variables
is changed within an action, that changed value is saved in the hash. For
example, given the specification:

        $args = Getopt::Declare->new( q{

        -ar <R:n>       Set aspect ratio (will be clipped to [0..1])
                                {
                                  $R = 0 if $R < 0;
                                  $R = 1 if $R > 1;
                                }
        } );

then the value of C<$args-E<gt>{'-ar'}{'E<lt>RE<gt>'}>
will always be between zero and one.


=item The C<@ARGV> array

In its "non-strict" mode, once a F<Getopt::Declare> object has
completed its command-line processing, it pushes any unrecognized
arguments back into the emptied command-line array C<@ARGV> (whereas
all I<recognized> arguments will have been removed).

Note that these remaining arguments will be in sequential elements
(starting at C<$ARGV[0]>), I<not> in their original positions in
C<@ARGV>.


=item The C<Getopt::Declare::usage()> method

Once a F<Getopt::Declare> object is created, its C<usage()> method may be called
to explicitly print out usage information corresponding to the specification
with which it was built. See L<"Usage information"> for more details.
If the C<usage()> method is called with an argument, that argument is passed
to C<exit> after the usage information is printed (the no-argument version of
C<usage()> simply returns at that point).


=item The C<Getopt::Declare::version()> method

Another useful method of a F<Getopt::Declare> object is C<version()>,
which prints out the name of the enclosing program, the last time it
was modified, and the value of C<$::VERSION>, if it is defined.
Note that this implies that I<all> F<Getopt::Declare> objects in a
single program will print out identical version information.

Like the C<usage()> method, if C<version> is passed an argument, it
will exit with that value after printing.


=item The C<Getopt::Declare::parse()> method

It is possible to separate the construction of a F<Getopt::Declare>
parser from the actual parsing it performs. If
C<Getopt::Declare::new()> is called with a second parameter C<'-BUILD'>
(see L<"Parsing from other sources">, it constructs and returns a
parser, without parsing anything.
The resulting parser object can then be used to parse multiple sources,
by calling its C<parse()> method. 

C<Getopt::Declare::parse()> takes an optional parameter which specifies
the source of the text to be parsed (it parses C<@ARGV> if the
parameter is omitted). This parameter takes the same set of values as the
optional second parameter of C<Getopt::Declare::new()> (see L<"Parsing
from other sources">).

C<Getopt::Declare::parse()> returns true if the source is located and
parsed successfully. It returns a defined false (zero) if the source is
not located. An C<undef> is returned if the source is located, but not
successfully parsed.

Thus, the following code first constructs a parser for a series of alternate
configuration files and the command line, and then parses them:

        # BUILD PARSERS
        my $config  = Getopt::Declare->new($config_grammar, -BUILD);
        my $cmdline = Getopt::Declare->new($cmdline_grammar, -BUILD);

        # TRY STANDARD CONFIG FILES
        $config->parse(-CONFIG)

        # OTHERWISE, TRY GLOBAL CONFIG
        or $config->parse('/usr/local/config/.demo_rc')

        # OTHERWISE, TRY OPENING A FILEHANDLE (OR JUST GIVE UP)
        or $config->parse(new FileHandle (".config") || -SKIP);

        # NOW PARSE THE COMMAND LINE

        $cmdline->parse() or die;


=item The C<Getopt::Declare::code()> method

It is also possible to retrieve the command-line parsing code generated
internally by C<Getopt::Declare::new()>. The C<Getopt::Declare::code()>
method returns a string containing the complete command-line processing
code, as a single C<do> block plus a leading C<package> declaration.

C<Getopt::Declare::code()> takes as its sole argument a string
containing the complete name of the package (for the leading
C<package> declaration in the generated code). If this string is empty
or undefined, the package name defaults to "main".

Since the default behaviour of C<Getopt::Declare::new()> is to execute
the command-line parsing code it generates, if the goal is only to 
generate the parser code, the optional second '-BUILD' parameter
(see L<"Parsing from other sources">) should be specified when calling
<Getopt::Declare::new()>.

For example, the following program "inlines" a C<Getopt::Declare>
specification, by extracting it from between the first "=for
Getopt::Declare" and the next "=cut" appearing on C<STDIN>:

        use Getopt::Declare;

        sub encode { return Getopt::Declare->new(shift,-BUILD)->code() || die }

        undef $/;
        if (<>)
        {
                s {^=for\s+Getopt::Declare\s*\n(.*?)\n=cut}
                  {'my (\$self,$source) = ({});'.encode($1).' or die "\n";'}
                  esm; 
        }

        print;

Note that the generated inlined version expects to find a lexical variable
named C<$source>, which tells it what to parse (this variable is
normally set by the optional parameters of C<Getopt::Declare::new()> or
C<Getopt::Declare::parse()>).

The inlined code leaves all extracted parameters in the lexical
variable C<$self> and does not autogenerate help or version flags
(since there is no actual F<Getopt::Declare> object in the inlined code
through which to generate them).

=back


=head1 AUTOGENERATED FEATURES

=head2 Usage information

The specification passed to C<Getopt::Declare::new> is used (almost
verbatim) as a "usage" display whenever usage information is
requested.

Such requests may be made either by specifying an argument matching
the help parameter (see L<"Help parameters">) or by explicitly calling
the C<Getopt::Declare::usage()> method (through an action or after
command-line processing):

        $args = Getopt::Declare->new( q{

                -usage          Show usage information and exit
                                        { $self->usage(0); }

                +usage          Show usage information at end of program
        } );

        # PROGRAM HERE 

        $args->usage()  if $args->{'+usage'};


The following changes are made to the original specification before
it is displayed:

=over 4

=item *

All actions and comments are deleted,

=item *

any C<[ditto]> directive is converted to an appropriate set of "ditto" marks,

=item *

any text in matching square brackets (including any directive) is deleted,

=item *

any parameter variable type specifier (":i", ":n", ":/pat/", etc.) is deleted.

=back

Otherwise, the usage information displayed retains all the formatting
present in the original specification.

In addition to this information, if the input source is @ARGV,
F<Getopt::Declare> displays three sample command-lines: one indicating
the normal usage (including any required parameter variables), one
indicating how to invoke help (see L<"Help parameters">), and one
indicating how to determine the current version of the program (see
L<"Version parameters">).

The usage information is printed to C<STDOUT> and (since F<Getopt::Declare>
tends to encourage longer and better-documented parameter lists) if
the F<IO::Pager> package is available, an F<IO::Pager> object is used to
page out the entire usage documentation.

=head2 Usage "decoration"

It is sometimes convenient to add other "decorative" features to a
program's usage information, such as subheadings, general notes,
separators, etc. F<Getopt::Declare> accommodates this need by ignoring
such items when interpreting a specification string, but printing them
when asked for usage information. 

Any line which cannot be interpreted as either a parameter
definition, a parameter description, or a parameter action, is treated
as a "decorator" line, and is printed verbatim (after any square
bracketted substrings have been removed from it). If your decoration needs
square brackets, you need to escape the opening square bracket with a
backslash, e.g. C<\[decoration]>.

The key to successfully decorating F<Getopt::Declare> usage
information is to ensure that decorator lines are separated from
any preceding parameter specification, either by an action or by an
empty line. In addition, like a parameter description, a decorator
line cannot contain a tab character after the first non-whitespace
character (because it would then be treated as a parameter
specification).

The following specification demonstrates various forms of usage
decoration. In fact, there are only four actual parameters (C<-in>,
C<-r>, C<-p>, and C<-out>) specified. Note in particular that I<leading>
tabs are perfectly acceptible in decorator lines.

        $args = Getopt::Declare->new(<<'EOPARAM');

        ============================================================
        Required parameter:

                -in <infile>            Input file [required]

        ------------------------------------------------------------

        Optional parameters:

                (The first two are mutually exclusive) [mutex: -r -p]

                -r[and[om]]             Output in random order
                -p[erm[ute]]            Output all permutations

                ---------------------------------------------------

                -out <outfile>          Optional output file

        ------------------------------------------------------------
        Note: this program is known to run very slowly of files with
              long individual lines.
        ============================================================
        EOPARAM


=head2 Help parameters

By default, F<Getopt::Declare> automatically defines I<all> of the following
parameters:

        -help   Show usage information [undocumented]
                        { $self->usage(0); }
        -Help   [ditto]
        -HELP   [ditto]
        --help  [ditto]
        --Help  [ditto]
        --HELP  [ditto]
        -h      [ditto]
        -H      [ditto]

Hence, most attempts by the user to get help will automatically work
successfully.

Note however that, if a parameter with any of these flags is
explicitly specified in the string passed to C<Getopt::Declare::new()>,
that flag (only) is removed from the list of possible help flags. For
example:

        -w <pixels:+i>  Specify width in pixels
        -h <pixels:+i>  Specify height in pixels

would cause the C<-h> help parameter to be removed (although help
would still be accessible through the other seven alternatives).


=head2 Version parameters

F<Getopt::Declare> also automatically creates a set of parameters which can be
used to retrieve program version information:

        -version        Show version information [undocumented]
                                { $self->version(0); }
        -Version        [ditto]
        -VERSION        [ditto]
        --version       [ditto]
        --Version       [ditto]
        --VERSION       [ditto]
        -v              [ditto]
        -V              [ditto]

As with the various help commands, explicitly specifying a parameter
with any of the above flags removes that flag from the list of version
flags.


=head1 DIAGNOSTICS

F<Getopt::Declare> may issue the following diagnostics whilst parsing a
command-line. All of them are fatal (the first five, instantly so):

=over 4

=item "Error: bad Getopt::Declare parameter variable specification near %s"

A matching pair of angle brackets were specified as part of a
parameter definition, but did not form a valid parameter variable
specification (that is, it wasn't in the form: <I<name>> or
<I<name>:I<type>>).

=item "Error: bad type in Getopt::Declare parameter variable specification near %s"

An unknown type specifier was used in a parameter variable type suffix.

=item "Error: bad action in Getopt::Declare specification:\n %s"

A Perl syntax error was detected in the indicated action.

=item "Error: unattached action in Getopt::Declare specification:\n %s"

An action was found for which there was no preceding parameter specification.
This usually occurs because the trailing tab was omitted from the preceding
parameter specification.

=item "Error: incomplete action in Getopt::Declare specification:\n %s"

An action was found, but it was missing one or more closing '}'s.

=item "Error: bad condition in directive [requires: %s]\n"

The condition specified as part of the indicated C<[requires:...]>
directive was not a well-formed boolean expression. Common problems
include: omitting a C<&&>/C<||> operator between two flags,
mismatched brackets, or using C<and>/C<or> instead of C<&&>/C<||>.

=item "Error: in generated command-line parser code:\n %s"

Either there was a Perl syntax error in one some action (which was
not caught by the previous diagnostic), or (less likely) there is a
bug in the code generator inside F<Getopt::Declare>.

=item "Error: incorrect specification of %s parameter"

The flag for the indicated parameter was found, but the argument did not
then match any of that parameter's variant syntaxes.

=item "Error: parameter %s not allowed with %s"

Two mutually exclusive flags were specified together.

=item "Error: required parameter %s not found"

No argument matching the specified "required" parameter was found
during command-line processing.

=item "Error: parameter %s can only be specified with %s"

The indicated parameter has a C<[requires:...]> directive, which
was not satisfied.

=item "Error: unknown command-line argument (%s)"

A command-line argument was encountered which did not match any
specified parameter. This diagnostic can only only appear if the
"strict" option is in effect.

=item "Error: in parameter %s (%s must be an integer greater than zero)"

A parameter variable in the indicated parameter was declared with the
type ":+i" (or a type derived from it), but the corresponding
argument was not a positive, non-zero integer.

=item "Error: in parameter %s (%s must be a number greater than zero)"

A parameter variable in the indicated parameter was declared with the
type ":+n" (or a type derived from it), but the corresponding
argument was not a positive, non-zero number.

=item "Error: in parameter %s (%s must be an positive integer)"

A parameter variable in the indicated parameter was declared with the
type ":0+i" (or a type derived from it), but the corresponding
argument was not a positive integer.

=item "Error: in parameter %s (%s must be a positive number)"

A parameter variable in the indicated parameter was declared with the
type ":0+n" (or a type derived from it), but the corresponding
argument was not a positive number.

=back

=head1 AUTHOR

Damian Conway <damian@conway.org>


=head1 BUGS AND ANNOYANCES

There are undoubtedly serious bugs lurking somewhere in this code.

If nothing else, it shouldn't take 1500 lines to explain a
package that was designed for intuitive ease of use!

Bug reports and other feedback are most welcome at:
https://rt.cpan.org/Public/Bug/Report.html?Queue=Getopt-Declare


=head1 COPYRIGHT

       Copyright (c) 1997-2000, Damian Conway. All Rights Reserved.
     This module is free software. It may be used, redistributed
     and/or modified under the terms of the Perl Artistic License
          (see http://www.perl.com/perl/misc/Artistic.html)
