
# For documentation for this module, please see the end of this file
# or try `perldoc Apache::ASP`

package Apache::ASP;

$VERSION = 2.62;

#require DynaLoader;
#@ISA = qw(DynaLoader);
#bootstrap Apache::ASP $VERSION;

use Digest::MD5 qw(md5_hex);
use Cwd qw(cwd);

# create multiple entries for this symbols for StatINC
use Fcntl qw(:flock O_RDWR O_CREAT); 

# load these always, but only load ::State, ::Session, ::Application
# at runtime in non mod_perl environments since they may not be needed
use Apache::ASP::GlobalASA;
use Apache::ASP::Response;
use Apache::ASP::Request;
use Apache::ASP::Server;
use Apache::ASP::Date;
use Apache::ASP::Lang::PerlScript;

use Carp qw(confess cluck);

use strict;
no strict qw(refs);
use vars qw($VERSION
	    %NetConfig %LoadedModules %LoadModuleErrors 
	    %Codes %includes %Includes %CompiledIncludes
	    @Objects %Register %XSLT
	    $ServerID $ServerPID $SrandPid 
            $CompileErrorSize $CacheSize @CompileChecksumKeys
	    %ScriptLanguages $ShareDir $INCDir $AbsoluteFileMatch
            $QuickStartTime
            $SessionCookieName
            $LoadModPerl
            $ModPerl2
	   );

# other common modules load now, these are optional though, so we do not error upon failure
# just do this once perl mod_perl parent startup
unless($LoadModPerl++) {
    my @load_modules = qw( Config lib Time::HiRes );
    if($ENV{MOD_PERL}) {
	# Only pre-load these if in a mod_perl environment for sharing memory post fork.
	# These will not be loaded then for CGI until absolutely necessary at runtime
	push(@load_modules, qw( 
          mod_perl
          MLDBM::Serializer::Data::Dumper Devel::Symdump CGI
          Apache::ASP::StateManager Apache::ASP::Session Apache::ASP::Application
          Apache::ASP::StatINC Apache::ASP::Error
          )
	    );
    }
    
    for my $module ( @load_modules ) {
         eval "use $module ();";
    }

    if(exists $ENV{MOD_PERL_API_VERSION}) {
	if($ModPerl2 = ($ENV{MOD_PERL_API_VERSION} >= 2)) {
	    if($ModPerl2) {
		eval "use Apache::ASP::ApacheCommon ();";
		die($@) if $@;
	    }
	}
    }
}

## HEADER TOKEN TWEAK
# This must be called outside the above load module block, so that
# its gets run whenever this module is loaded
# This didn't work in 1.27 mod_perl, with DSO enabled, would
# put the Apache::ASP token in front.
# eval {     &Apache::add_version_component("Apache::ASP/$VERSION"); };
# $Apache::Server::AddPerlVersion = 1;

#use integer; # don't use screws up important numeric logic

@Objects = ('Application', 'Session', 'Response', 'Server', 'Request');
map { eval "sub $_ { shift->{$_} }" } @Objects;

# use regexp directly, not sub for speed
$AbsoluteFileMatch = '^(/|[a-zA-Z]:)';
$CacheSize = 1024*1024*10;
$SessionCookieName = 'session-id';

# ServerID creates a unique identifier for the server
srand();
$ServerID = substr(md5_hex($$.rand().time().(-M('..')||'').(-M('/')||'')), 0, 16);
$ServerPID  = $$;

# DEFAULT VALUES
$Apache::ASP::CompileErrorSize = 500;
@CompileChecksumKeys = qw ( Global DynamicIncludes UseStrict XMLSubsMatch XMLSubsPerlArgs XMLSubsStrict GlobalPackage UniquePackages IncludesDir InodeNames PodComments );

%ScriptLanguages = (
		    'PerlScript' => 1,
		   );

&InitPaths();

%Apache::ASP::LoadModuleErrors = 
  (
   'Filter' => 
   "Apache::Filter was not loaded correctly for using SSI filtering.  ".
   "If you don't want to use filtering, make sure you turn the Filter ".
   "config option off whereever it's being used",

   Clean => undef,
   
   CreateObject => 
   'OLE-active objects not supported for this platform, '.
   'try installing Win32::OLE',
   
    Gzip =>
   'Compress::Zlib is needed to make gzip content-encoding work, '.
   'If you want to use this feature, get yourself the latest '.
   'Compress::Zlib from CPAN. ',
   
   HiRes => undef,

   FormFill => 
   'HTML::FillInForm is needed to use the FormFill feature '.
   'for auto filling forms with $Response->Form() data',

   MailAlert => undef,
   
   SendMail => "No mailing support",
   
   StateDB => 
   'cannot load StateDB '.
   'must be a valid perl module with a db tied hash interface '.
   'such as: SDBM_File (default), or DB_File',
   
   StateSerializer =>
   'cannot load StateSerializer '.
   'must be a valid serializing perl module for use with MLDBM '.
   'such as Data::Dumper (default), or Storable',

   StatINC => "You need this module for StatINC, please download it from CPAN",
   
   'Cache' => "You need this module for xml output caching",

   XSLT => 'Cannot load XML::XSLT.  Try installing the module.',

  );


sub handler {
    my($package, $r) = @_;
    my $status = 200;
    
    # allows it to be called as an object method
    ref $package and $r = $package;

    # default to Apache request object if not passed in, for possible DSO fix
    # rarely happens, but just in case
    my $filename;
    unless($filename = eval { $r->filename }) {
        my $rtest = $ModPerl2 ? Apache2::RequestUtil->request() : Apache->request();
	if($filename = eval { $rtest->filename }) {
	    $r = $rtest;
	} else {
	    return &DSOError($rtest);
	}
    }

    # better error checking ?
    $filename ||= $r->filename();
    # using _ is optimized to use last stat() record
    return(404) if (! -e $filename or -d _);

    # alias $0 to filename, bind to glob for bug workaround
    local *0 = \$filename;

    # ASP object creation, a lot goes on in there!
    # method call used for speed optimization, as OO calls are slow
    my $self = &Apache::ASP::new('Apache::ASP', $r, $filename);

    # for runtime use/require library loads from global/INCDir
    # do this in the handler section to cover all the execution stages
    # following object set up as possible.
    local @INC = ($self->{global}, $INCDir, @INC);

    # Execute if no errors
    $self->{errs} || &Run($self);
    
    # moved print of object to the end, so we'll pick up all the 
    # runtime config directives set while the code is running

    $self->{dbg} && $self->Debug("ASP Done Processing $self", $self );

    # error processing
    if($self->{errs}) {
	require Apache::ASP::Error;
	$status = $self->ProcessErrors;
    }

    # XX return code of 302 hangs server on WinNT
    # STATUS hook back to Apache
    my $response = $self->{Response};
    if($status != 500 and defined $response->{Status} and $response->{Status} != 302) {
	# if still default then set to what has been set by the 
	# developer
	$status = $response->{Status};
    }

    # X: we DESTROY in register_cleanup, but if we are filtering, and we 
    # handle a virtual request to an asp app, we need to free up the 
    # the locked resources now, or the session requests will collide
    # a performance hack would be to share an asp object created between
    # virtual requests, but don't worry about it for now since using SSI
    # is not really performance oriented anyway.
    # 
    # If we are not filtering, we let RegisterCleanup get it, since
    # there will be a perceived performance increase on the client side
    # since the connection is terminated before the garabage collection is run.
    # 
    # Also need to destroy if we return a 500, as we could be serving an
    # error doc next, before the cleanup phase

    if($self->{filter} || ($status == 500) || ( $r->isa('Apache::ASP::CGI'))) {
	$self->DESTROY();
    }

    if($status eq '200') {
	$status = 0; # OK status code is default unless there was an internal error
    }

    $status;
}

sub Warn {
    shift if(ref($_[0]) or $_[0] eq 'Apache::ASP');
    print STDERR "[ASP WARN] ", @_;
}

sub new {
    my($class, $r, $filename) = @_;
    $r || die("need Apache->request() object to Apache::ASP->new(\$r)");

    # $StartTime is set by asp-perl early on before modules are loaded
    # for more accurate per time tracking.  Unset, so this init load time does 
    # not get used more than once.
    my $start_time;
    if($QuickStartTime) {
	$start_time = $QuickStartTime;
	$QuickStartTime = undef;
    } else {
	$start_time = eval { &Time::HiRes::time(); } || time();
    }

    local $SIG{__DIE__} = \&Carp::confess;
    # like cgi, operate in the scripts directory
    $filename ||= $r->filename();
    $filename =~ m|^(.*?[/\\]?)([^/\\]+)$|;
    my $dirname = $1 || '.';
    my $basename = $2;
    chdir($dirname) || die("can't chdir to $dirname: $!");

    # temp object just to call config() on, do not bless since we
    # do not want the object to be DESTROY()'d
    my $dir_config = $r->dir_config;
    my $headers_in = $r->headers_in;
    my $self = { r => $r, dir_config => $dir_config };

    # global is the default for the state dir and also 
    # a default lib path for perl, as well as where global.asa
    # can be found
    my $global = &get_dir_config($dir_config, 'Global') || '.';
    $global = &AbsPath($global, $dirname);

    # asp object is handy for passing state around
    $self = bless 
      { 
       'basename'       => $basename,
       'cleanup'        => [],
       'dbg'            => &get_dir_config($dir_config, 'Debug') || 0,  # debug level
       'destroy'        => 1,
       'dir_config'     => $dir_config,
       'headers_in'     => $headers_in,
       filename         => $filename,
       global           => $global,
       global_package   => &get_dir_config($dir_config, 'GlobalPackage'),
       inode_names      => &get_dir_config($dir_config, 'InodeNames'),
       no_cache         => &get_dir_config($dir_config, 'NoCache'),
       'r'              => $r, # apache request object 
       start_time       => $start_time,
       stat_scripts     => &config($self, 'StatScripts', undef, 1),
       stat_inc         => &get_dir_config($dir_config, 'StatINC'),    
       stat_inc_match   => &get_dir_config($dir_config, 'StatINCMatch'),
       use_strict       => &get_dir_config($dir_config, 'UseStrict'),
       win32            => ($^O eq 'MSWin32') ? 1 : 0,
       xslt             => &get_dir_config($dir_config, 'XSLT'),
      }, $class;

    # Only if debug is negative do we kick out all the internal stuff
    if($self->{dbg}) {
	if($self->{dbg} < 0) {
	    *Debug = *Out;
	    $self->{dbg} = -1 * $self->{dbg};
	} else {
	    *Debug = *Null;
	}
	$self->Debug('RUN ASP (v'. $VERSION .") for $self->{filename}");

    } else {
	*Debug = *Null;
    }
    
    # Ken said no need for seed ;), now we just make sure its called post fork
    # Patch from Ime suggested no need for %SrandPid, just srand() again when $$ has changed
    unless($SrandPid && $SrandPid == $$) {
	$self->{dbg} && $self->Debug("call srand() post fork");
	srand();
	$SrandPid = $$;
    }

    # filtering support
    my $filter_config = &get_dir_config($dir_config, 'Filter');
    if($filter_config) { 
        if($self->LoadModules('Filter', 'Apache::Filter')) {
	    # new filter_register with Apache::Filter 1.013
	    if($r->can('filter_register')) {
		$self->{r} = $r = $r->filter_register;
	    }
	    
	    if ($r->can('filter_input') && $r->can('get_handlers')) {
		$self->{filter} = 1;
		#X: do something with the return code, can't now because
		# apache constants aren't working on my win32
		my($fh, $rc) = $r->filter_input();
		$self->{filehandle} = $fh;
	    }
	} else {
	    if(! $r->can('get_handlers')) {
		$self->Error("You need at least mod_perl 1.16 to use SSI filtering");
	    } else {
		$self->Error("Apache::Filter was not loaded correctly for using SSI filtering.  ".
			     "If you don't want to use filtering, make sure you turn the Filter ".
			     "config option off whereever it's being used");
	    }
	}
    }
    
    # gzip content encoding option by ime@iae.nl 28/4/2000
    my $compressgzip_config = &get_dir_config($dir_config, 'CompressGzip');
    if($compressgzip_config) {
	if($self->LoadModule('Gzip','Compress::Zlib')) {
	    $self->{compressgzip} = 1;
	}
    }    
     
    # must have global directory into which we put the global.asa
    # and possibly state files, optimize out the case of . or ..
    if($self->{global} !~ /^(\.|\.\.)$/) {
	-d $self->{global} or 
	  $self->Error("global path, $self->{global}, is not a directory");
    }

    # includes_dir calculation
    if($filename =~ m,^((/|[a-zA-Z]:).*[/\\])[^/\\]+?$,) {
	$self->{dirname} = $1;
    } else {
	$self->{dirname} = '.';
    }
    $self->{includes_dir} = [
			     $self->{dirname},
			     $self->{global}, 
			     split(/;/, &config($self, 'IncludesDir') || ''),
			    ];

    # register cleanup before the state files get set in InitObjects
    # this way DESTROY gets called every time this script is done
    # we must cache $self for lookups later
    &RegisterCleanup($self, sub { $self->DESTROY });

    #### WAS INIT OBJECTS, REMOVED DECOMP FOR SPEED

    # GLOBALASA, RESPONSE, REQUEST, SERVER
    # always create these
    # global_asa assigns itself to parent object automatically
    my $global_asa = &Apache::ASP::GlobalASA::new($self);
    $self->{Request}   = &Apache::ASP::Request::new($self);
    $self->{Response}  = &Apache::ASP::Response::new($self);
    # Server::new() is just one line, so execute directly
    $self->{Server}    = bless {asp => $self}, 'Apache::ASP::Server';
    #&Apache::ASP::Server::new($self);

    # After GlobalASA Init, init the package that this script will execute in
    # must be here, and not end of new before things like Application_OnStart get run
    # UniquePackages & NoCache configs do not work together, NoCache wins here
    if(&config($self, 'UniquePackages')) {
	# id is not generally useful for the ASP object now, so calculate
	# it here now, only to twist the package object for this script

	# pass in basename for where to find the file for InodeNames, and the full path
	# for the FileId otherwise
	my $package = $global_asa->{'package'}.'::'.&FileId($self, $self->{basename}, $self->{filename});
	$self->{'package'} = $package;
	$self->{init_packages} = ['main', $global_asa->{'package'}, $self->{'package'}];	
    } else {
	$self->{'package'} = $global_asa->{'package'};
	$self->{init_packages} = ['main', $global_asa->{'package'}];	
    }

    $self->{state_dir}   = &config($self, 'StateDir', undef, $self->{global}.'/.state');
    $self->{state_dir}   =~ tr///; # untaint

    # if no state has been config'd, then set up none of the 
    # state objects: Application, Internal, Session
    unless(&get_dir_config($dir_config, 'NoState')) {
	# load at runtime for CGI environments, preloaded for mod_perl
	require Apache::ASP::StateManager;
	&InitState($self);
    }

    $self;
}

# called upon every end of connection by RegisterCleanup
sub DESTROY {
    my $self = shift;

    return unless $self->{destroy}; # still active object
    $self->{dbg} && $self->Debug("destroying ASP object $self");

    # do before undef'ing the object references in main
    for my $code ( @{$self->{cleanup}} ) {
	$self->{dbg} && $self->Debug("executing cleanup $code");
	eval { &$code() };
	$@ && $self->Error("executing cleanup $code error: $@");
    }

    local $^W = 0; # suppress untie while x inner references warnings
    select(STDOUT); 
    untie *RESPONSE if tied *RESPONSE;

    # can't move this to Request::DESTROY(), then CGI object compatibility
    # in test ./site/eg/cgi.htm test fails, don't know why, --jc, 12/06/2002
    untie *STDIN if tied *STDIN;

    # in case there is a dummy session here by the 
    # end of object execution
    if($self->{Session}) {
        if(eval { $self->{Session}->isa('Apache::ASP::Session') }) {
	    # only the cleanup master may cleanup groups now, so OK
	    # to call just CleanupGroups
	    $self->CleanupGroups();
	} else {
            $self->Debug("$self->{Session} is not an Apache::ASP::Session");
            eval { $self->{Session}->DESTROY };
            $self->{Session} = undef;
        }
    }

    # free file handles here.  mod_perl tends to be pretty clingy
    # to memory
    for('Application', 'Internal', 'Session') {
	# all this stuff in here is very necessary for total cleanup
	# the DESTROY is the most important, as we need to explicitly free
	# state objects, just in case anyone else is keeping references to them
	# But the destroy won't work without first untieing, go figure
	next unless defined $self->{$_};
	my $tied = tied %{$self->{$_}};
	next unless $tied;
	untie %{$self->{$_}};
	$tied->DESTROY(); # call explicit DESTROY
    }

    if(my $caches = $self->{Caches}) {
	# default cache size to 10M
	$self->{cache_size} = &config($self, 'CacheSize') || $CacheSize;
	if($self->{cache_size} =~ /^([\d\.]+)(M|K|B)?$/) {
	    my($size, $unit) = ($1, $2);
	    if($unit eq 'M') {
		$size *= 1024*1024;
	    } elsif($unit eq 'K') {
		$size *= 1024;
	    }
	    if($size ne $self->{cache_size}) {
		$self->{dbg} && $self->Debug("converting CacheSize $self->{cache_size} to $size bytes");
		$self->{cache_size} = $size;
	    }
	}
	for my $cache (values %$caches) {
	    my $tied = $cache;
	    if($tied->{writes} && $tied->Size > $self->{cache_size}) {
		$self->{dbg} && $self->Debug("deleting cache $cache, size: ".$tied->Size);
		$tied->Delete;
	    } else {
		$self->{dbg} && $self->Debug("cache $cache OK size, size: ".$tied->Size);
	    }
	    $tied->DESTROY();
	}
    }

    #    $self->{'dbg'} && $self->Debug("END ASP DESTROY");
    $self->{Request} && &Apache::ASP::Request::DESTROY($self->{Request});
    $self->{Server} && ( %{$self->{Server}} = () );
    $self->{Response} && ( %{$self->{Response}} = () );
    %$self = ();

    1;
}

sub RegisterCleanup {
    my $self = shift;

    if($ModPerl2) {
	$self->{r}->pool->cleanup_register(@_);
    } else {
	$self->{r}->register_cleanup(@_);
    }
}

sub InitPaths {

    # we load this module just to detect where the shared directory really is
    use Apache::ASP::Share::CORE;

    # major problem with %INC if we cannot get this information
    my $share_path = $INC{'Apache/ASP/Share/CORE.pm'} 
      || die(q(can't find path for $INC{'Apache/ASP/Share/CORE.pm'}));

    $share_path =~ s/CORE\.pm$//s;
    unless($share_path =~ /$AbsoluteFileMatch/) {
	# this %ENV manipulation is just to allow cwd() to run in taint check mode
	local %ENV = %ENV;
	$ENV{PATH} = '/bin:/usr/bin:/usr/sbin';
	delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
	my $currdir = cwd();
	$share_path = "$currdir/$share_path";
    }

    # not finding the ShareDir creates a hard error, because the Apache/ASP/Share
    # directory will become one of the fundamental underpinings of the project
    # People will need to rely on being able to load shared includes, and not have
    # to discover the lack of loading Share:: at runtime, rather this is a compile
    # time error.
    -d $share_path || die("Apache::ASP::Share directory not found.  ".
			  "Please make sure to install all the modules that make up the Apache::ASP installation."
			 );
    $ShareDir = $share_path;

    # once we find the $ShareDir, we can truncate the library path
    # and push it onto @INC with use lib... this is to help with loading
    # future Apache::ASP::* modules when the lib path it was found at is 
    # relative to some directory.  This was needed to have the "make test"
    # test suite to work which loads libraries from "blib/lib", but Apache::ASP
    # will chdir() into the script directory so that can ruin this
    # library lookup.
    #
    my $lib_path = $share_path;
    $lib_path =~ s/Apache.ASP.Share.?$//s;
    -d $lib_path || die("\%INC library path $lib_path not found.");
    $INCDir = $lib_path;
    
    # clear taint, for some reason, tr/// or s/^(.*)$/ did not work on perl 5.6.1
    $INCDir =~ /^(.*)$/s;
    $INCDir = $1;

    # make sure this gets on @INC at startup, can't hurt
    eval "use lib qw($INCDir);";

    1;
}

sub FileId {
    my($self, $file, $abs_file, $no_compile_checksum) = @_;
    $file || die("no file passed to FileId()");
    my $id;

    # calculate compile checksum for file id
    unless($self->{compile_checksum}) {
	my $r = $self->{r};
	my $checksum = md5_hex(join('&-+', 
				    $VERSION,
				    map { &config($self, $_) || '' }
				    @CompileChecksumKeys
				   )
			      );
	#    $self->{dbg} && $self->Debug("compile checksum $checksum");
	$self->{compile_checksum} = $checksum;
    }

    my $compile_checksum = $no_compile_checksum ? '' : $self->{compile_checksum};

    my @inode_stat = ();
    if($self->{inode_names}) {
	@inode_stat = stat($file);
	# one or the other device or file ids must be not 0
	unless($inode_stat[0] || $inode_stat[1]) {
	    @inode_stat = ();
	}
    }

    if(@inode_stat) {
	$id = sprintf("____DEV%X_INODE%X",@inode_stat[0,1]);
	$id .= 'x'.$compile_checksum;
    } else {
	if($abs_file) {
	    $file = $abs_file;
	}
	$file =~ s|/+|/|sg;
	$file =~ s/[\Wx]/_/sg;
	my $file_name_length = length($file);
	if($file_name_length >= 35) {
	    $id = substr($file, $file_name_length - 35, 36);
	    # only do the hex of the original file to create a unique identifier for the long id
	    $id .= 'x'.&md5_hex($file.$compile_checksum);
	} else {
	    $id = $file.'x'.$compile_checksum;
	}
    }

    $id = '__ASP_'.$id;
}

# defaults to parsing the script's file, or data from a file handle 
# in the case of filtering, but we can also pass in text to parse,
# which is useful for doing includes separately for compiling
sub Parse {
    my($self, $file) = @_;
    my $file_exists = 0;
    my $parse_file = $file;
    my $r = $self->{r};
    my $data;

    # get script data, from varied data sources; 
    $file || die("can't parse without file data");

    $self->{dbg} && $self->Debug("parse file $file");
    # file can be a filename, scalar ref, or scalar
    if(ref $file) {
	if ($file =~ /SCALAR/) {
	    $data = $$file;
	} elsif ($file =~ /GLOB/) {
	    local $/ = undef;
	    $data = <$file>
	}
    } elsif((length($file) < 1024) && ($file !~ /^GLOB/) && (-e $file)) {
	# filename has length < 1024, should be fine across OS's
	$self->{dbg} && $self->Debug("parsing $file");
	$data = ${$self->ReadFile($file)};
	$file_exists = 1;
	$self->{parse_file_count}++;
    } else {
	$data = $file; # raw script, no ref
    }

    # moved parsing config here since not needed for normal
    # eval execution of scripts after compilation
    unless($self->{parse_config}) {
	$self->{parse_config} = 1;
	$self->{compile_includes} = &config($self, 'DynamicIncludes');
	$self->{pod_comments} = &config($self, 'PodComments', undef, 1);
	$self->{xml_subs_strict} = &config($self, 'XMLSubsStrict');
	# default XMLSubsPerlArgs to 1 for now, until 3.0
	$self->{xml_subs_perl_args} = &config($self, 'XMLSubsPerlArgs', undef, 1);

	# reduce (pattern) patterns to (?:pattern) to not create $1 side effect
	if($self->{xml_subs_match} = &config($self, 'XMLSubsMatch')) {
	    $self->{xml_subs_match} =~ s/\(\?\:([^\)]*)\)/($1)/isg;
	    $self->{xml_subs_match} =~ s/\(([^\)]*)\)/(?:$1)/isg;
	}

	my $lang = &config($self, 'ScriptLanguage', undef, 'PerlScript');
	my $module = "Apache::ASP::Lang::".$lang;
	unless($ScriptLanguages{$lang}) {
#	    eval "use $module;";
	    $self->Error("ScriptLanguage for $lang could not be loaded: $@");	    
	    return;
	}
	eval {
	    my $lang_object = $module->new(ASP => $self);
	    $self->{lang_object} = $lang_object;
	    $self->{lang_module} = $module;
	    $self->{lang_language} = $lang;
	    $self->{lang_comment} = $lang_object->CommentStart;
	};
	if($@) {
	    $self->Error("ScriptLanguage object for $lang failed init: $@");
	    return;
	}
    }

    my $comment = $self->{lang_comment};
    if(&config($self, 'CgiDoSelf')) {
	$data =~ s,^(.*?)__END__,,so;
    }

    # do both before and after, so =pods can span includes with =pods
    if($self->{pod_comments}) {
	&PodComments($self, \$data);
    }

    # if compiling includes, then do now before includes conversion
    # each include will also have its Script_OnParse run on it.
    if($self->{compile_includes} && $self->{GlobalASA}{'exists'}) {	
	$self->{Server}{ScriptRef} = \$data;
	$self->{GlobalASA}->ExecuteEvent('Script_OnParse');		
    }

    # do includes as early as possible !! so included text gets done too
    # this section is for file includes, we do this here instead of ssi
    # so it can be parsed and compiled with the script
    local %includes; # trap recursive includes with this

    # JUST ONCE
    # there should only be one of these, <%@ LANGUAGE="PerlScript" %>, rip it out
    # we keep white space and substitue text in so the perlscript sync's up with lines
    # only take out the first one 
    $data =~ s/^\#\![^\n]+(\n\s*)/\<\%$1\%\>/s; #X cgi compat ?
    $data =~ s/^(\s*)\<\%(\s*)\@([^\n]*?)\%\>/$1\<\%$2 ; \%\>/so; 

    my $root_file = $file;
    my $line1_added = 0;
    my $munge = $data;
    $data = '';
    my($file_context, $file_line_number, $code_block);
    while($munge =~ s/^(.*?)\<!--\#include\s+file\s*=\s*\"?([^\s\"]*?)\"?(\s+args\s*=\s*\"?.*?)?\"?\s*--\>//so) {
	$data .= $1; # append the head
	my $file = $2;

	# only need all this if we are in inline include mode
	my $head_data;
	if (! $self->{compile_includes}) {
	    $head_data = $1;

	    unless($line1_added) {
		$line1_added = 1;
		$head_data = ($file_exists ? "<% \n#line 1 $root_file\n %>" : '').$head_data;
	    }

	    if ($head_data =~ s/.*\n\#line (\d+) ([^\n]+)\n(\%\>)?//s) {
		$file_line_number = $1;
		$file_context = $2;
		$code_block = $3 ? 0 : 1;
	    }
	    $file_line_number += $head_data =~ s/\n//sg;
	    $head_data =~ s/\<\%.*?\%\>//sg;
#	    print STDERR "HEAD: $head_data\n";
	    my $code_blocks_open   = $head_data =~ s/\<\%//sg;
	    my $code_blocks_closed = $head_data =~ s/\%\>//sg;
	    $code_block += $code_blocks_open;
	    $code_block -= $code_blocks_closed;
	    if (($code_block < 0)) {
		$code_block = 0; # stray percents like height=100%> kinds of tags
	    }

#	    print STDERR "CODEBLOCK: $code_block $file; open $code_blocks_open closed $code_blocks_closed\n";
#	    print STDERR "FILE CONTEXT: $file_context LINENO: $file_line_number\n\n";
	}

	# compiled include args handling
	my $has_args = $3;
	my $args = undef;
	if($has_args) {
	    $args = $has_args;
	    $args =~ s/^\s+args\s*\=\s*\"?//sgo;
	}

	# global directory, as well as includes dirs
	my $include = &SearchDirs($self, $file);
	unless(defined $include) { 
	    $self->Error("include file with name $file does not exist");
	    return;
	}
	if($self->{dbg}) {
	    if($include ne $file) {
		$self->{dbg} && $self->Debug("found $file at $include");
	    }
	}

	# trap the includes here, at 100 levels like perl debugger
	if(defined($args) || $self->{compile_includes}) {
	    # because the script is literally different whether there 
	    # are includes or not, whether we are compiling includes
	    # need to be part of the script identifier, so the global
	    # caching does not return a script with different preferences.
	    $args ||= '';
	    $self->{dbg} && $self->Debug("runtime exec of dynamic include $file args (".
					 ($args).')');
	    $data .= "<% \$Response->Include('$include', $args); %>";
	    
	    # compile include now, so Loading() works for dynamic includes too
	    unless($self->CompileInclude($include)) {
		$self->Error("compiling include $include failed when compiling script");
	    }		   
	} else {
	    $self->{dbg} && $self->Debug("inlining include $include");
	    # DEFAULT, not compile includes, or inline includes,
	    # the included text is inlined directly into the script
	    if($includes{$include}++ > 100) {
		$self->Error("Recursive include detected for $include 100 levels deep! ".
			     "Your includes are including each other.  If you ".
			     "are getting this error with a legitimate use of includes ".
			     "please mail support about this error "
			    );
		return;
	    }
	    
	    # put the included text into what we are parsing, allows for
	    # includes having includes
	    if ($file_exists && $parse_file) {
		$self->{parse_inline_count}++;
		$self->{dbg} && $self->Debug("include $include found for file $parse_file");
		$Apache::ASP::Includes{$parse_file}->{$include} = time();
	    }
	    my $text = ${$self->ReadFile($include)};
	    $text =~ s/\n$//sg;
	    $text =~ s/^\#\![^\n]+(\n\n?)/$1/s; #X cgi compat ?
	      ;
	    if ($text =~ /\n/s) {
		my $code_open = $code_block ? '' : '<%';
		my $code_close = $code_block ? '' : '%>';
		my $file_context_edge = $file_context ? 
		  $code_open."\n#line $file_line_number $file_context\n".$code_close : '';
		$munge =
		  $code_open."\n#line 1 $include\n".$code_close.
		    $text .
		      $file_context_edge .
			$munge;
	    } else {
		# if inserting less than one line of text, then don't
		# do line renumbering
		$munge = $text . $munge;
	    }
	}
    }
    $data .= $munge; # append what's left   
#    print STDERR $file."\n\n".$data."\n\n";


    # so we have the full script for people
    if(! $self->{compile_includes}) {	
	# do pod comments again if we have any included files
	if(%includes && $self->{pod_comments}) {
	    &PodComments($self, \$data);
	}
	if($self->{GlobalASA}{'exists'}) {	
	    $self->{Server}{ScriptRef} = \$data;
	    $self->{GlobalASA}->ExecuteEvent('Script_OnParse');		
	}
    }

#    $self->Debug("parsing includes done $self->{'basename'}");

    # strip carriage returns; do this as early as possible, but after includes
    # since we want to rip out the carriage returns from them too, these
    # changes should make things Win & Mac compatible
#    my $CRLF = "\015\012";
    $data =~ s/\015?\012/\n/sgo;
    $data =~ s/\s+$//so; # strip trailing white space

    my $script = &ParseHelper($self, \$data, 1);
    if($script) {
	my $strict = $self->{use_strict} ? "use strict;" : "no strict";
	$$script = join(";;", 
			$strict,
			"use vars qw(\$".join(" \$",@Apache::ASP::Objects).')',
			($file_exists ? "\n#line 1 $root_file\n" : ''),
			$$script,
		       );
	return {
		is_perl => 1,
		data => $script,
	       };
    } else {
	return {
		is_raw => 1,
		data => \$data,
	       };
    }
}

sub ParseHelper {
    my($self, $data, $check_static_file) = @_;
    my($script, $text, $perl);

    if($self->{xml_subs_match}) {
	my $start = $$data;
	$self->{dbg} && $self->Debug("start parse of data", length($$data));
	$$data = $self->ParseXMLSubs($$data);
#	print STDERR "START $start\n\n";
#	print STDERR "END $$data\n\n";
    }

    # we only do this check the first time we call ParseHelper() from
    # Parse() with $check_static_file set.  Calls from ParseXMLSubs()
    # will leave this off.  This is where we start to throw data 
    # back that lets the system render a static file as is instead
    # of executing it as a per subroutine.
    return if ($check_static_file && $$data !~ /\<\%.*?\%\>/s);

    my(@out, $perl_block, $last_perl_block);
    $$data .= "<%;;;%>"; # always end with some perl code for parsing.

# can't do it for <%= %><% %> constructions
#    $$data =~ s/\%\>(\s*)\<\%/;$1/isg; # compress close code blocks, move white space to code

    while($$data =~ s/^(.*?)\<\%(.*?)\%\>//so) {
	($text, $perl) = ($1,$2);
	$perl_block = ($perl =~ /^\s*\=(.*)$/so) ? 0 : 1;
	my $perl_scalar = $1;

	# with some extra text parsing, we remove asp formatting from
	# influencing the generated html formatting, in particular
	# dealing with perl blocks and new lines
	if($text) {
	    # don't touch the white space, to preserve line numbers
	    $text =~ s/\\/\\\\/gso;
	    $text =~ s/\'/\\\'/gso;

	    if($last_perl_block) {
		$last_perl_block = 0;
	    }

	    push(@out, "\'".$text."\'")
	}

	if($perl) {
	    if(! $perl_block) {
		# we have a scalar assignment here
		push(@out, '('.$perl_scalar.')');
	    } else {
		$last_perl_block = 1;
		if(@out) {
		    # we pass by reference here with the idea that we are not
		    # copying the HTML twice this way.  This might be large
		    # saving on a typical site with rich HTML headers & footers
		    $script .= '&Apache::ASP::WriteRef($main::Response, \('.join('.', @out).'));';
#		    $script .= '$main::Response->{Bit} = \('.join('.', @out).');';
#		    $script .= '($main::Response->{Buffer} && ! $main::Response->{Ended}) ? '.
#		      '${$main::Response->{out}} .= ${$main::Response->{Bit}} : '.
#			'$main::Response->WriteRef($main::Response->{Bit}); ';
		    @out = ();
		}			 

		# allow old <% #comment %> style to still work, but we
		# need to insert a newline at the end of the comment for 
		# it to still exist, with the lines now being sync'd up
		# if these old comments still exist, they perl script
		# will be off by one line from the asp script
		if ($perl !~ /\n\s*$/so) {
		    if($perl =~ /\#[^\n]*$/so) {
#			print STDERR "NEW adding newline to [$perl]\n";
			$perl .= "\n";
		    }
		}

		# skip if the perl code is just a placeholder		
		unless($perl eq ';;;') {
#		    print STDERR "PERL, adding ; to [$perl]\n";
		    $script .= $perl . '; ';
		}
	    }
	}
    }

    \$script;
}

sub ParseXMLSubs {
    my($self, $data) = @_;

    $data = &CodeTagEncode($self, $data);

    unless($self->{xslt}) {
	$data =~ s|\s*\<\?xml\s+version\s*\=[^\>]+\?\>||is;
    }
    # (?<!\s|\>) ... use later when robustifying XMLSubs
    $data =~ s@\<\s*($self->{xml_subs_match})(\s+[^\>]*)?/\>
	  @ {
	     my($func, $args) = ($1, $2);
	     $args = &CodeTagDecode($self, $args);
	     $func =~ s/\:+/\:\:/g;
             $func =~ s/\-/\_/g;
	     $args && ($args = &ParseXMLSubsArgs($self, $args));
	     $args ||= '';
	     $self->{xmlsubs_compiled_tag_short}++;
             "<% &$func({ $args }, ''); %>"
	    } @sgex;

    while (1) {
	# 	  \<\s*($self->{xml_subs_match})(\s+[^\>]*)?\>(?!.*\<\s*\1[^\>]*\>)(.*?)\<\/\1\s*>
	last unless $data =~ s@
	  \<\s*($self->{xml_subs_match})(\s+[^\>]*)?\>(?!.*?\<\s*\1[^\>]*\>)(.*?)\<\/\1\s*>
          @ {
	      my($func, $args, $text) = ($1, $2, $3);
	      $args = &CodeTagDecode($self, $args);
	      $func =~ s/\:+/\:\:/g;
	      $args && ($args = &ParseXMLSubsArgs($self, $args));
	      $args ||= '';
	      $self->{xmlsubs_compiled_tag_long}++;
	      $text = &CodeTagDecode($self, $text);

		if($text =~ m/\<\%|\<($self->{xml_subs_match})/) {
		    # parse again, and control output buffer for this level
		    $self->{xmlsubs_compiled_tag_recurse_parse}++;
		    my $sub_script = &ParseHelper($self, \$text, 0);
		    #		    my $sub_script = \$text;
		    $text = (
			     ' &{sub{ my $out = ""; '.
			     'local $Response->{out} =  local $Response->{BinaryRef} = \$out; '.
			     'local *Apache::ASP::Response::Flush = *Apache::ASP::Response::Null; '.
			     $$sub_script .
			     ' ; ${$Response->{out}}; }} '
			    );
		} else {
		    # raw text
		    $text =~ s/\\/\\\\/gso;
		    $text =~ s/\'/\\\'/gso;	
		    $text = "'$text'";
		}
		
		"<% &$func({ $args }, $text); %>"
	  } @sgex;
    }

    $data = &CodeTagDecode($self, $data);

#    print STDERR "\nXMLSubs:\n$data\n\n";

    $data;
}

sub CodeTagEncode {
    my($self, $data) = @_;
#    return $data;

    if(defined $data) {
       $data =~ s@\<\%(.*?)\%\>@
         {
             my $temp = $self->{Server}->HTMLEncode($1);
             "[-AsP-[".$temp."]-AsP-]";
         }
           @esgx;
    }
    $data;
}

sub CodeTagDecode {
    my($self, $data) = @_;
#    return $data;

    if(defined $data) {
       $data =~ s@\[\-AsP\-\[(.*?)\]\-AsP\-\]@
         {
             my $temp = $self->{Server}->HTMLDecode($1);
             "<%".$temp."%>";
         }
           @esgx;
    }

    $data;
}

sub ParseXMLSubsArgs {
    my($self, $args) = @_;
    $args ||= '';

    if ($self->{xml_subs_strict}) {
	my %args;
	while ($args =~ s/(\s*)([^\s]+)(\s*)\=\s*([\'\"])(.*?)(\4)\s*//s) {
	    $args{$2} = $5;
	}
	$args = join(', ', map { "'$_' => '$args{$_}'" } keys %args);
    } elsif($self->{xml_subs_perl_args}) {
	$args =~ s/(\s*)([^\s]+?)(\s*)\=(\s*[^\s]+)/,$1'$2'$3\=\>$4/sg;
	$args =~ s/^(\s*),/$1/s;
    } else {
	my %args;
	while ($args =~ s/(\s*)([^\s]+?)(\s*)\=\s*([\'\"])(.*?)(\4)\s*//s) {
	    my($key, $value) = ($2, $5);
	    # we go through the pain of @value_bits so that someone can 
	    # pass in non scalar data to XMLSubs args like:
	    #   <my:tag data="<%= [ 'data' ] %>" />
	    # As long as the <%= %> bits are flush against the 
	    # 
	    my @value_bits;
	    while($value =~ s/^(.*?)<\%\=(.*?)\%\>/
		  {
		   length($1) && push(@value_bits, "'$1'");
		   push(@value_bits, "($2)");
		   ''; # return nothing to replace with
		  }
		  /exs
		 ) { 1 };
	    length($value) && push(@value_bits, "'$value'");
	    $args{$key} = join('.', @value_bits);
	}
	$args = join(', ', map { "'$_' => $args{$_}" } keys %args);
    }

#    print STDERR "ARGS: $args\n";
    $args;
}

sub PodComments {
    my $data = $_[1];
    
    # we do a little extra work to sync pod comment lines up, we do this
    # by wiping out the pod comments, and replacing them with the equivalent
    # number of newlines
    $$data =~ s/\015?\012/\n/sgo;
    $$data =~ s,(^|\n)(\=pod\n.*?\n\=cut\n),
      {
       my $pod = $1.$2;
       $pod =~ s/[^\n]+//sg;
       $pod;
      }
    ,sgex;
    
    $data;
}

sub SearchDirs {
    my($self, $file) = @_;
    return unless defined $file;

    my $share_search;
    if($file =~ s/^Share:://) {
	$share_search = 1;
    }

    my @includes_dir = @{$self->{includes_dir}};
    if($share_search) {
	push(@includes_dir, $ShareDir);
    }

    # optimization for includes in tight for loops, a typical usage,
    # to save on the stats per request.  This must occur after @include_dir
    # per lookup because @includes_dir may change during the request
    #
    my $cache_key = join('||', $file, @includes_dir);
    if(my $path = $self->{search_dirs_cache}{$cache_key}) {
	# $self->Debug("found $path search cached for $file, key $cache_key");
	return $path;
    }

    # test & return if absolute
    if($file =~ m,^/|^[a-zA-Z]\:,) {
	if(-e $file && ! -d _) {
	    return $file;
	} else {
	    return undef;
	}
    }

    for my $dir (@includes_dir) {
	my $path = "$dir/$file";
	$path =~ s|/+|/|isg;
	if(-e $path && ! -d _) {
	    $self->{search_dirs_cache}{$cache_key} = $path;
	    return $path;
	}
    }

    undef;
}

sub RegisterIncludes {
    my($self, $script) = @_;

    # compile includes at compile time, for prefork parse optimization
    my $copy = $$script;
    $copy =~ s/\$Response\-\>Include\([\'\"]([^\$]+?)[\'\"]/
      {
       my $include = $1;
       # prevent recursion
       unless($self->{register_includes}{$include}) {
	   $self->{register_includes}{$include} = 1;
	   local $self->{compile_error} = undef;
	   local $self->{compile_eval} = undef;
	   my $code = eval { $self->CompileInclude($include); };
	   my $debug = $code ? "success" : "error: $@";
	   $self->{dbg} && $self->Debug("register include $include with $debug");
       }
       '';
      }
	/exsgi;
}

sub CompileInclude {
    my($self, $include, $package, $is_base_script) = @_;
    my($include_ref, $mtime, $subid);

    local $self->{use_strict} = $self->{use_strict};
    if($include =~ /^Share::/) {
	# Share:: components must always run under UseStrict
	$self->{use_strict} = 1;
    }
    
    if ( ref $include ) {
#	$self->{dbg} && $self->Debug("compiling scalar data $include for include");
	$include_ref = $include;
#	$include = $$include;
    } else { # file here
	if($is_base_script) {
	    # if its the base script being executed, then we already know
	    # it exists because of earlier file tests, and do not need to
	    # search for it
	    #
	    # leave $include alone
	} else {
	    # streamlined, SearchDirs now caches per request
	    my $file = &SearchDirs($self, $include);
	    die("no include $include") unless defined $file;
	    $include = $file;
	}

	# treat as anonymous subroutine compilation like data passed in 
	# as a scalar ref as above if we have NoCache set
	if($self->{no_cache}) {
	    $include = $self->ReadFile($include);
	    $include_ref = $include;
	    goto COMPILE_INCLUDE_PARSE;
	}

	my $id = &FileId($self, $include);
	$subid = ($package || $self->{GlobalASA}{'package'})."::$id".'xINC';

	my $compiled = $Apache::ASP::CompiledIncludes{$subid};
	if($compiled && ! $self->{stat_scripts}) {
	    $self->{dbg} && $self->Debug("no stat: found cached code for include $id");
	    return $compiled;
	}
	
	# return cached code if include hasn't been modified recently
	$mtime = (stat($include))[9];
	if($compiled && ($compiled->{mtime} > $mtime)) {
	    #	$self->Debug("found cached code for include $id");

	    # now check for changed includes, return if not changed
	    my $includes_changed = 0;
	    if(my $includes = $Apache::ASP::Includes{$include}) {
		for my $k (keys %$includes) {
		    my $v = $includes->{$k} || 0;
		    my @stat = stat($k);
		    if(@stat) {
			if($stat[9] >= $v) {
			    $self->{dbg} && $self->Debug("file $k mtime changed from $v to $stat[9]");
			    $includes_changed = 1;
			    last;
			}
		    } else {
			$self->{dbg} && $self->Debug("can't get mtime for file $k: $!");
			$includes_changed = 1;
			last;
		    }
		}
	    }

	    if(! $includes_changed) {
		return $compiled;
	    } else {
		$self->{dbg} && $self->Debug("includes changed for $include, recompiling");
	    }
	}
    }

COMPILE_INCLUDE_PARSE:
    
    my $parse_data = $self->Parse($include);
    my $no_cache = $self->{no_cache};
    my $data;

#    use Data::Dumper qw(Dumper);
#    print STDERR Dumper($include, $parse_data);
#    $self->Debug($self);

    if ($parse_data->{is_perl}) {
       my $sub = $self->CompilePerl($parse_data->{data}, $subid, $package);

       # for perl with subs in it, do not cache the code compilation
       # to help prevent my closure problems for newbies, --jc 2/11/2003
       unless($no_cache) {
	   $no_cache = $self->TestForSubs($parse_data->{data});
	   if($no_cache) {
	       $self->Debug("test for subs returned $no_cache, no_cache = $no_cache");
	   }
       }

       if ($sub) {
	   $data = { 
		    mtime => time(), 
		    code => $sub,
                    perl => $parse_data->{data},
		    file => $include_ref || $include,
		   };
       }
    } elsif($parse_data->{is_raw}) {
       $data = {
                mtime => time(),
                code => $parse_data->{data},
                perl => $parse_data->{data},
                file => $include_ref || $include,
               };
    } else {
	$data = undef;
    }

    if ($data && $subid && ! $no_cache) { # for a returned code ref, don't cache
	$Apache::ASP::CompiledIncludes{$subid} = $data;
    }

    $data;
}

sub UndefRoutine {
    my($self, $subid) = @_;

    my $code = \&{$subid};
    if($code) {
	$self->{dbg} && $self->Debug("undefing sub $subid code $code");
	undef(&$code); # method for perl 5.6.1
	undef($code);  # older perls ??
    }
}

sub ReadFile {
    my($self, $file) = @_;

    local *READFILE;
    open(READFILE, $file) || $self->Error("can't open file $file for reading");
    local $/ = undef;
    my $data = <READFILE>;
    close READFILE;

    \$data;
}

# if the $file is an absolute path, then just return the file
# if the $file is a relative path, concat it with the passed in directory
sub AbsPath {
    my($file, $dir) = @_;

    # we test for first unix style and then win32 style path conventions
    if($file =~ m|^/| or $file =~ m|^.\:|) {
	$file;
    } else {
	# we only can absolute the path if the directory path is absolute
	if($dir =~ m|^/| or $dir =~ m|^.\:|) {
	    $file = $dir.'/'.$file;
	} else {
	    $file;
	}
    }
}       

sub CompilePerl {
    my($self, $script, $subid, $package) = @_;
    $package ||= $self->{GlobalASA}{'package'};
    $subid ||= '';

    ref($script) || die("no ref to perl script to compile");
    $subid && $self->UndefRoutine($subid);
    $self->{dbg} && $self->Debug("compiling into package $package subid [$subid]");    

    $self->{compile_perl_count}++; # counter used in test case closure.t

    my $eval = 
      join(" ;; ", 
	   "package $package;", # for no sub closure
	   "sub $subid { ",
	   "package $package;", # for sub closure
	   $$script,
	   '}',
	  );
#    $eval =~ tr///; # untaint
    $eval =~ /^(.*)$/s;
    $eval = $1;

    my $sub_ref;

    if($self->{use_strict}) { 
	local $SIG{__WARN__} = sub { die("maybe use strict error: ", @_) };

	# comment out for now, until 3.0 release for this may create lots
	# of compile time errors for people that will need to fix scripts
	#	local $^W = 1; # trigger my closure errors, --jc 9/7/2002
	$sub_ref = eval $eval;
    } else {
	local $SIG{__WARN__} = sub { $self->Out(@_) };
	$sub_ref = eval $eval;
    }

    my $rv; # for readability
    my $error = $@;

    if($@) {
	$self->CompileError($eval); # don't throw error, so we can throw die later
	$subid && $self->UndefRoutine($subid);
	$rv = undef;
    } else {
	if($subid) {
	    if(&config($self, 'RegisterIncludes')) {
		$self->RegisterIncludes($script);
	    }
	    $rv = $subid;
	} else {
	    $rv = $sub_ref;
	}
    }

    $@ = $error;
    $rv;
}

sub TestForSubs {
    my($self, $script) = @_;
    $$script =~ /(^|\n)\s*sub\s+([^\s\{]+)\s*\{/ ? 1 : 0;
}

sub InitPackageGlobals {
    my $self = shift;

    unless($self->{response_tied}) {
	# set printing to Response object
	$self->{response_tied} = 1;
	tie *RESPONSE, 'Apache::ASP::Response', $self->{Response};
	select(RESPONSE);
    }

    # ---- init package objects ----
    # unoptimized this because we should only call this function once
    # and maybe twice if there is a defined Script_OnStart
    for my $object (@Apache::ASP::Objects) {
	for my $import_package (@{$self->{init_packages}}) {
	    my $init_var = $import_package.'::'.$object;
	    $$init_var = $self->{$object};	}
    }

    undef;
}

sub Run {
    my $self = shift;    

    ($self->{stat_inc_match} || $self->{stat_inc}) && $self->StatINC;

    my $compiled;
    if(! $self->{errs}) {
	my $compile_file = $self->{filehandle}; # filehandle for filtering
	unless($compile_file) {
	    # need SearchDirs() to make full path for base file, test suite is 
	    # not OK with using $self->{filename}
	    $compile_file = $self->SearchDirs($self->{basename});
	    unless($compile_file) { 
		$self->Error("no file found for $self->{basename}");
		return;
	    }
	}

	$compiled = $self->CompileInclude($compile_file, $self->{'package'}, 1);

	unless($compiled) {
	    $self->Error("error compiling $self->{basename}: $@");
	    return;
	}
	$self->{run_perl_script} = $compiled->{perl};
    }

    # must have all the variabled defined outside the scope
    # of the eval in case End() jumps to the goto below, since
    # the variables in the local eval{} scope will be cleared
    # upon return.
    my $global_asa = $self->{GlobalASA};

    eval { 
	$global_asa->{'exists'} && $global_asa->ScriptOnStart;
	$self->{errs} || $self->Execute($compiled->{code});

      APACHE_ASP_EXECUTE_END:
	$self->{errs} || ( $global_asa->{'exists'} && $global_asa->ScriptOnEnd() );
	$self->{errs} || $self->{Response}->EndSoft();
    };

    if($@) {
	# its not really a compile time error, but might be useful
	# to render for a runtime error anyway
	# $self->CompileError($compiled->{perl});
	$self->Error("error executing $self->{basename}: $@");
    }

    ! $@;
}

sub Execute {
    my($self, $code) = @_;
    $code || die("no subroutine passed to Execute()");
    $self->{dbg} && $self->Debug("executing $code");

    # set up globals as early as Application_OnStart, also
    # allows variables to be changed in Script_OnStart for running script
    &InitPackageGlobals($self);

    if(my $ref = ref $code) {
	if($ref eq 'CODE') {
	    eval { &$code(); };
	} elsif($ref eq 'SCALAR') {
#	    $self->{dbg} && $self->Debug("writing cached static file data $code, length: ".length($$code));
	    $self->{Response}->WriteRef($code);
	} else {
	    $self->Error("$code is a ref, but not CODE or SCALAR!");
	}
    } else {
	# if absolute package already, then no need to set to package namespace
	my $subid = ( $code =~ /::/ ) ? $code : $self->{GlobalASA}{'package'}.'::'.$code;
	eval { &$subid(); };
    }

    if($@) { 
	$self->Error($@); 
    }
    
    ! $@;
}

sub Cache {
    my($self, $cache_name, $key, $value, $expires, $last_modified, $no_check_meta) = @_;
    $cache_name || die("no cache_name given");
    grep($cache_name eq $_, qw(XSLT Response)) || die("cache_name $cache_name is invalid");
    return unless defined($key);

    my $cache_dbm = $self->{Caches}{$cache_name};
    if(defined $cache_dbm) {
	$self->{dbg} && $self->Debug("found cache $cache_dbm for $cache_name");
    } else {
	# load at runtime for CGI environments, preloaded for mod_perl
	require Apache::ASP::State;

	local $self->{state_dir} = &config($self, 'CacheDir') || $self->{state_dir};
	local $self->{state_db} = &config($self, 'CacheDB') || 'MLDBM::Sync::SDBM_File';
	$self->{dbg} && $self->Debug("CacheDB set to $self->{state_db}");
	$cache_dbm = Apache::ASP::State::new($self, $cache_name, 'cache')
	  || ($self->Error("could not do cache $cache_name: $!") && return);
	$self->{Caches}{$cache_name} = $cache_dbm;
	$self->{dbg} && $self->Debug("init cache $cache_dbm for $cache_name");
    }

    $key = (ref($key) && ($key =~ /SCALAR/)) ? $$key : $key;
    my $checksum = &md5_hex($key).'x'.length($key);
    my $metakey = $checksum . 'xMETA';
    my $rv;

    eval {
	$cache_dbm->{dbm}->Lock;
	if(defined $value) {
	    my $meta = { ServerID => $ServerID, Creation => time() };
	    if(defined $expires && ($expires =~ /^\-?\d+$/)) {
		$meta->{Expires} = $expires;
		$meta->{Timeout} = time + $expires;
	    };
	    $self->{dbg} && $self->Debug("storing $checksum in $cache_name cache");
	    $cache_dbm->STORE($metakey, $meta);
	    $self->{cache_count_store}++;
	    $rv = $cache_dbm->STORE($checksum, $value);
	} else {
	    # don't check meta data for XSLT since transformations don't expire ever
	    if($no_check_meta) {
		$self->{dbg} && $self->Debug("cache $cache_name fetch checksum $checksum no check meta");
		$self->{cache_count_fetch}++;
		$rv = $cache_dbm->{dbm}->FETCH($checksum);
	    } else {
		my $meta = $cache_dbm->{dbm}->FETCH($metakey);
		my $new;
		if(! $meta) {
		    $meta = { Creation => 0, ServerID => 'NULL' };
		    $new = 1;
		} else {
		    # NEW EXPIRES FOR EXISTING ITEM
		    if(defined $expires && ($expires =~ /^\-?\d+$/) && ($expires != $meta->{Expires})) {
			$self->Debug("new expires $expires, old ".($meta->{Expires} || '')." for $checksum");
			$meta->{Expires} = $expires;
			# use creation timestamp for expires calculation, not current
			# time, or we would refresh the entry
			$meta->{Timeout} = $meta->{Creation} + $expires;
			$cache_dbm->STORE($metakey, $meta);
		    };
		}
		
		# LastModified calculations
		if(defined $last_modified) {
		    if($last_modified !~ /^\d+$/) {
			my $old_last_modified = $last_modified;
			$last_modified = &Apache::ASP::Date::str2time($last_modified);
			$self->{dbg} && $self->Debug("converting string date for LastModified $old_last_modified to unix time $last_modified");
		    }
		    if($last_modified < 0) {
			$self->{dbg} && $self->Debug("negative LastModified $last_modified ignored");
			$last_modified = undef;
		    }
		}
		
		# EARLY TIMEOUT CALCULATION
		if($meta->{Timeout}) {
		    # 10% chance to expire early to prevent collision
		    my $early = ($meta->{Expires} || 0) * rand() * '.1';
		    $self->{dbg} && $self->Debug("will reduce expires for $meta->{Expires} by random $early seconds, checksum $checksum");
		    $meta->{Timeout} = $meta->{Timeout} - $early;
		}
		
		$self->{dbg} && $self->Debug("meta cache data for checksum $checksum", $meta);
		
		if($new) {
		    $self->{dbg} && $self->Debug("no cache entry, checksum $checksum");
		    $self->{cache_count_miss}++;
		    $rv = undef;
		} elsif(defined $meta->{ServerID} && ($$ ne $ServerPID) && ($meta->{ServerID} ne $ServerID)) {
		    # can only run like this when running in preloaded mod_perl mode
		    # This will allow for caching in other modes that simply does not reset
		    # upon server restart
		    $self->{dbg} && $self->Debug("cache expires new server $ServerID, was $meta->{ServerID}");
		    $self->{cache_count_restart}++;
		    $rv = undef;
		} elsif($meta->{Timeout} && ($meta->{Timeout} <= time())) {
		    $self->{dbg} && $self->Debug("cache expires timeout $meta->{Timeout}, checksum $checksum, time ".time);
		    $self->{cache_count_expires}++;
		    $rv = undef;
		} elsif(defined($last_modified) && ($last_modified >= $meta->{Creation})) {
		    $self->{dbg} && $self->Debug("cache expires, checksum $checksum, LastModified $last_modified, Creation $meta->{Creation}");
		    $self->{cache_count_last_modified_expires}++;
		    $rv = undef;
		} else {
		    $self->{dbg} && $self->Debug("cache $cache_name fetch checksum $checksum");
		    $self->{cache_count_fetch}++;
		    $rv = $cache_dbm->{dbm}->FETCH($checksum);
		}
	    }
	}
	$cache_dbm->{dbm}->UnLock;
    };
    if($@) {
	$self->Out("[ASP WARN] error using cache $cache_name: $@");
	$self->{cache_count_error}++;
	eval { $cache_dbm->{dbm}->UnLock; };
    }

    $rv;
}

sub XSLT {
    my($self, $xsl_data, $xml_data) = @_;
    my $asp = $self;

    my $cache = &config($self, 'XSLTCache');
    my $cache_data = $$xsl_data.$$xml_data;

    if($cache) {
	if(my $data = $self->Cache('XSLT', \$cache_data, undef, undef, undef, 1)) {
	    return $data;
	}
    }

    ref($xsl_data) || die("xsl data must be a scalar ref");

    my $xslt_parser = &config($self, 'XSLTParser') || 'XML::XSLT';

    my @parsers = ('XML::XSLT 0.32', 'XML::Sablotron', 'XML::LibXSLT');
    my $xslt_parser_lib;
    unless (($xslt_parser_lib) = grep(/^$xslt_parser/, @parsers)) {
	die("$xslt_parser must be one of: ".join(',', @parsers));
    }

    $asp->{dbg} && $asp->Debug("using xslt parser $xslt_parser_lib");
    eval "use $xslt_parser_lib";
    $@ && die("failed to load $xslt_parser_lib: $@");

    my $xslt_data = '';
    return \$xslt_data unless(length($$xsl_data) && length($$xml_data));

    if ($xslt_parser eq 'XML::XSLT') {
	my $xslt = XML::XSLT->new($xsl_data);
	$xslt->transform($xml_data);
	$xslt_data = $xslt->toString;
	$xslt->dispose;
    } elsif ($xslt_parser eq 'XML::Sablotron') {
	my $error = &XML::Sablotron::ProcessStrings($$xsl_data, $$xml_data, $xslt_data);
	if ($error) {
	    die "error on XML::Sabltron::ProcessStrings: $error, $@, $!";
	}
    } elsif ($xslt_parser eq 'XML::LibXSLT') {
	my $parser = XML::LibXML->new();
	my $xslt = XML::LibXSLT->new();
	my $source = $parser->parse_string($$xml_data);
	my $style_doc = $parser->parse_string($$xsl_data);
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	my $results = $stylesheet->transform($source);
	$xslt_data = $stylesheet->output_string($results);
    }

    if($cache) {
	$self->Cache('XSLT', \$cache_data, \$xslt_data);
    }

    \$xslt_data;
}

sub Log {
    my($self, @msg) = @_;
    my $msg = join(" ", @msg);
    $msg =~ s/[\r\n]+/ \<\-\-\> /sg;    
    if($self->{r}) {
	$self->{r}->log_error("[asp] [$$] $msg");
    } else {
	print STDERR "[WARN] [asp] [$$] [Invalid ASP Object $self] $msg\n";
    }
}

sub CompileErrorThrow {
    my($self, $eval, @errors) = @_;
    $self->CompileError($eval);
    $self->Error(@errors);
}

sub CompileError {
    my($self, $eval) = (shift, shift);
    $self->{compile_error} = 1;
    if(ref $eval) {
	my $copy_eval = $$eval;
	$self->{compile_eval} = \$copy_eval;
    } else {
	$self->{compile_eval} = \$eval;
    }
}

sub Error {
    my($self, $msg) = @_;
    
    my($package, $filename, $line) = caller;
    $msg .= ", $filename line $line";
    
    # error logging in $self
    $self->{errs}++;
    my $pretty_msg = $msg;
    $pretty_msg = $self->Escape($pretty_msg);
    $pretty_msg =~ s/\n/<br>/sg;

    push(@{$self->{errors_output}}, $msg);
    push(@{$self->{debugs_output}}, $msg);
    
    $self->Log("[error] $msg");
    
    1;
}   

# sub Debug { # for matching
*Debug = *Out; # default
sub Null() { 0; }; # prototype for inlining hopefully
sub Out {
    my($self, @args) = @_;

    # already know because of aliasing
    #    return unless $_[0]->{dbg};

    my(@data, $arg);
    while(@args) {
	$arg = shift @args;
	my($ref, $data);
	if($ref = ref($arg)) {
	    if($arg =~ /HASH/) {
		$data = '';
		for my $key (sort keys %{$arg}) {
		    my $value = defined($arg->{$key}) ? $arg->{$key} : '';
		    $data .= "$key: $value; ";
		}
	    } elsif($arg =~ /ARRAY/) {
		$data = join('; ', @$arg);
	    } elsif($arg =~ /SCALAR/) {
		$data = $$arg;
	    } elsif($arg =~ /CODE/) {
		my $out = eval { &$arg };
		if($@) {
		    $data = $@;
		} else {
		    unshift(@args, $out);
		    next;
		}
	    } else {
		$data = $arg;
	    }
	} else {
	    $data = $arg;
	}
	push(@data, $data);
    }

    my $debug = join(' - ', @data);
    my $time = '';
    if($self->{dbg} >= 3) {
	# use require, not LoadModule, so to avoid Debug recursion
	if(eval { require Time::HiRes; }) {
	    $time = sprintf("%.4f", Time::HiRes::time());
	    my $diff = sprintf("%.4f", $time - ($self->{last_time} || $time));
	    $self->{last_time} = $time;
	    $time = " [$time;$diff]";	    
	}
    }
    $self->Log("[debug]$time $debug");
    push(@{$self->{debugs_output}}, $debug);
    
    # someone might try to insert a debug as a scalar, better 
    # not to print anything
    undef; 
}

sub Escape {
    my($self, $html) = @_;

    $html =~s/&/&amp;/gs;
    $html =~s/\"/&quot;/gs;
    $html =~s/>/&gt;/gs;
    $html =~s/</&lt;/gs;

    $html;
}

# quickly decomped out of Apache::ASP just to optionally load
# it at runtime for CGI programs ( which shouldn't need it anyway )
# will still precompile this for mod_perl
#
sub StatINC {
    my $self = shift;
    require Apache::ASP::StatINC;
    $self->StatINCRun;
}

sub SendMail {
    my($self, $mail, %args) = @_;
    my($smtp, @to, $server);
    my $rv = 1;

    # load option mail modules
    for('Net::Config', 'Net::SMTP') {
	eval "use $_";
	if($@) {
	    die("no mailing errors because can't load $_: $@");
	    return 0;
	}
    }
    
    # configure mail host
    if($self->{mail_host} = &config($self, 'MailHost')) {
	unless($NetConfig{smtp_hosts} && (($NetConfig{smtp_hosts}->[0] || '') eq $self->{mail_host})) {
	    unshift(@{$NetConfig{smtp_hosts}}, $self->{mail_host});
	}
    }
    $mail->{From} ||= &config($self, 'MailFrom');

    unless($mail->{Test}) {
	for('To', 'Body', 'Subject', 'From') {
	    $mail->{$_} ||
	      die("need $_ argument to send mail");
	}
    }

    # debugging set in mail args, or general debugging
    if(! defined($args{Debug}) && defined($mail->{Debug})) {
	$args{Debug} = $mail->{Debug};
	delete $mail->{Debug};
    }
    if(! defined($args{Debug})) {
	# in case of system level debugging, mark Net::SMTP debug also
	if((&config($self, 'Debug') || 0) < 0) {
	    $args{Debug} = 1;
	}
    }

    # connect to server
    {
	local $SIG{__WARN__} = sub { $self->Debug('Net::SMTP->new() warning', @_) };
	if($mail->{Test}) {
	    $args{Timeout} = 5;
	}
	$smtp = Net::SMTP->new(%args);
    }
    unless($smtp) {
	$self->Out("[ERROR] can't connect to SMTP server with args ", \%args);
	return 0;
    } else {
	$self->Debug("connected to SMTP server with args ", \%args);
    }

    for my $receivers (qw(To BCC CC)) {
	next unless $mail->{$receivers};
	my @receivers = (ref $mail->{$receivers}) ? @{$mail->{$receivers}} : (split(/\s*,\s*/, $mail->{$receivers}));
	push(@to, @receivers);
    }

    $self->Debug("sending mail to: ".join(',', @to));
    ($mail->{From}) = split(/\s*,\s*/,($mail->{From} || '')); # just the first one

    $smtp->mail($mail->{From}) || return(0);

    # put test before $smtp->to() because we might get a relaying denied error otherwise
    if($mail->{Test}) {
	return $rv;
    }

    $smtp->to(@to) || return(0);

    my($data);
    my $body = $mail->{Body};
    delete $mail->{Body};

    # assumes MIME-Version 1.0 for Content-Type header, according to RFC 1521
    # http://www.ietf.org/rfc/rfc1521.txt
    if($mail->{'Content-Type'} && ! $mail->{'MIME-Version'}) {
	$mail->{'MIME-Version'} = '1.0';
    }

    my %done;
    for('Subject', 'From', 'Reply-To', 'Organization', 'To', keys %$mail) {
	next unless $mail->{$_};
	next if $done{lc($_)}++;	
	my $add = ref($mail->{$_}) ? join(",", @{$mail->{$_}}) : $mail->{$_};
	$add =~ s/^[\n]*(.*?)[\n]*$/$1/;
	$data .= "$_: $add\n";
    }
    $data .= "\n" . $body;

    $smtp->data($data) || ($rv = 0);
    $smtp->quit();

    $rv && $self->Debug("mail sent successfully");
    $rv;
}

*LoadModule = *LoadModules;
sub LoadModules {
    my($self, $category, @modules) = @_;
    my $load_errors = 0;
    
    for(@modules) {
	if(defined $LoadedModules{$_}) {
	    if($LoadedModules{$_} == 0) {
		if($LoadModuleErrors{$category}) {
		    $self->Error("cannot load $_ for $category: $LoadModuleErrors{$category}; $@");
		} else {
		    $self->Debug("already failed to load $_");
		}
		$load_errors++;
	    } 
	    next;
	}

	$_ =~ tr///; # untaint
	eval "use $_";
	if($@) { 
	    if($LoadModuleErrors{$category}) {
		$self->Error("cannot load $_ for $category: $LoadModuleErrors{$category}; $@");
	    } else {
		# don't wan't Log() output for make test when optional modules aren't installed
		# is not installed, --jc 6/11/2001
		$self->Debug("cannot load $_ for $category: $@");
	    }
	    $load_errors++;
	    $LoadedModules{$_} = 0;
	} else {
	    $self->{dbg} && $self->Debug("loaded module $_");
	    $LoadedModules{$_} = 1;
	}
    }
    
    ! $load_errors;
}

sub Loader {
    # this is enough to load Apache::ASP::Load, we only need to do it
    # at runtime since the purpose of Loader() is to be run from 
    # the httpd.conf during parent startup time, so this module will
    # be cached just fine at that time.
    #
    require Apache::ASP::Load;
    &Apache::ASP::Load::Run(@_);
}

sub DSOError {
    my $r = shift;

    # this could happen with a bad filtering sequence
    warn(<<ERROR);
No valid request object ($r) passed to ASP handler

If you are getting this error message and are using mod_perl 1.x and Apache 1.x,
you likely have a broken DSO version of mod_perl which often occurs
when using RedHat RPMs.  One fix reported is to configure "PerlSendHeader On".
Another fix is to compile statically the apache + mod_perl build as
RedHat RPMs have been trouble.

If you are using a newer mod_perl2 + Apache2, make sure you have
upgraded to the last Apache::ASP release, and report the issue
if problems continue to the Apache::ASP mailing list.  As of
December 2002, mod_perl2 + Apache2 combination is still experimental
and under development.

Please check FAQ or mod_perl archives for more information.

ERROR
  ;

	500;
}

sub CompileChecksumKeys() { \@CompileChecksumKeys };

sub get_dir_config {
    my $rv = shift->get(shift);
    if(lc($rv) eq 'off') {
	$rv = 0; # Off always becomes 0
    }
    $rv;
}

*Config = *config;
sub config {
    my($self, $key, $value, $default) = @_;
    my $dir_config = $self->{dir_config};

    if(defined $value) {
	$dir_config->set($key, $value);
    } elsif(defined $key) {
	my $rv = $dir_config->get($key);
	if(defined($rv)) {
	    if(lc($rv) eq 'off') {
		$rv = 0; # Off always becomes 0
	    }
	} else {
	    # use default value if none is returned
	    if(defined($default)) {
		$rv = $default;
	    }
	}
	$rv;
    } else {
	$dir_config;
    }
}

1;

__END__

=pod

=head1 NAME

  Apache::ASP - Active Server Pages for Apache with mod_perl 

=head1 SYNOPSIS

  SetHandler  perl-script
  PerlModule  Apache::ASP
  PerlHandler Apache::ASP
  PerlSetVar  Global /tmp/asp

=head1 DESCRIPTION

Apache::ASP provides an Active Server Pages port to the 
Apache Web Server with Perl scripting only, and enables developing 
of dynamic web applications 
with session management and embedded Perl code.  There are also 
many powerful extensions, including XML taglibs, XSLT rendering, 
and new events not originally part of the ASP API!

=begin html

<table class="noescape" border="0"><tr><td>
<b>Apache::ASP's features include:</b>
<font face=verdana,helvetica,arial size=-1>
<ul>
<li> Scripting SYNTAX is Natural and Powerful 
<li> Rich OBJECTS Developer API
<li> Web Application EVENTS Model
<li> Modular SSI Decomposition, Code Sharing
<li> User SESSIONS, CIFS & NFS Cluster Ready
<li> XML/XSLT Rendering & Custom Tag Technology
<li> CGI Compatibility
<li> PERLSCRIPT Compatibility
<li> Great Open Source SUPPORT
</ul>
</font>
</table>

=end html

This module works under the Apache Web Server
with the mod_perl module enabled. See http://www.apache.org and
http://perl.apache.org for further information.

This is a portable solution, similar to ActiveState's PerlScript
for NT/IIS ASP.  Work has been done and will continue to make ports 
to and from this implementation as smooth as possible.

For Apache::ASP downloading and installation, please read 
the INSTALL section.  For installation troubleshooting
check the FAQ and the SUPPORT sections.

For database access, ActiveX, scripting languages, and other
miscellaneous issues please read the FAQ section.

=head1 WEBSITE

The Apache::ASP web site is at http://www.apache-asp.org/
which you can also find in the ./site directory of 
the source distribution.

=head1 INSTALL

The installation process for Apache::ASP is geared towards those
with experience with Perl, Apache, and unix systems.  For those
without this experience, please understand that the learning curve 
can be significant.  But what you have at the end will be a web site
running on superior open source software.

If installing onto a Windows operating system, please see the section
titled Win32 Install.

=head2 Need Help

Often, installing the mod_perl part of the Apache server
can be the hardest part.  If this is the case for you, 
check out the FAQ and SUPPORT sections for further help,
as well as the "Build Apache" notes in this section.

Please also see the mod_perl guide at http://perl.apache.org/guide
which one ought to give a good read before undertaking
a mod_perl project.

=head2 Download and CPAN Install

You may download the latest Apache::ASP from your nearest CPAN,
and also:

  http://cpan.org/modules/by-module/Apache/
  ftp://ftp.duke.edu/pub/perl/modules/by-module/Apache/

As a Perl developer, you should make yourself familiar with 
the CPAN.pm module, and how it may be used to install
Apache::ASP, and other related modules.  The easiest way
to install Apache::ASP for the first time from Perl is to 
fire up the CPAN shell like:

 shell prompt> perl -MCPAN -e shell
  ... configure CPAN ...
  ... then upgrade to latest CPAN ...
 cpan> install CPAN
  ...
 cpan> install Bundle::Apache::ASP

Installing the Apache::ASP bundle will automatically install
all the modules Apache::ASP is dependent on as well as
Apache::ASP itself.  If you have trouble installing the bundle,
then try installing the necessary modules one at a time:

 cpan> install MLDBM
 cpan> install MLDBM::Sync
 cpan> install Digest::MD5  *** may not be needed for perl 5.8+ ***
 cpan> install Apache::ASP

For extra/optional functionality in Apache::ASP 2.31 or greater, like
support for FormFill, XSLT, or SSI, you can install this bundle via CPAN:

  cpan> install Bundle::Apache::ASP::Extra

=head2 Regular Perl Module Install

If not doing the CPAN install, download Apache::ASP and install it using 
the make or nmake commands as shown below.  Otherwise, just 
copy ASP.pm to $PERLLIB/site/Apache

  > perl Makefile.PL
  > make 
  > make test
  > make install

  * use nmake for win32

Please note that you must first have the Apache Web Server
& mod_perl installed before using this module in a web server
environment.  The offline mode for building static html at
./cgi/asp may be used with just perl.

=head2 Win32 / Windows Install

If you are on a Win32 platform, like WinNT or Windows 2000, 
you can download the win32 binaries linked to from:

  http://perl.apache.org/distributions.html  

From here, I would recommend the mod_perl binary installation at:

  ftp://theoryx5.uwinnipeg.ca/pub/other/

and install the latest perl-win32-bin-*.exe file.

Randy Kobes has graciously provided these, which include
compiled versions perl, mod_perl, apache, mod_ssl,
as well as all the modules required by Apache::ASP
and Apache::ASP itself.

You may also try the more recent Perl-5.8-win32-bin.exe
distribution which is built on Apache 2.  This should be
treated as BETA release software until mod_perl 2.x is 
released as stable. Some notes from Randy Kobes about 
getting this release to work are here:

  After installing this distribution, in Apache2\conf\perl.conf
  (pulled in via Apache2\conf\httpd.conf) there's directives that
  have Apache::ASP handle files placed under the Apache2\asp\
  directory. There should be a sample Apache::ASP script there,
  printenv.html, accessed as http://127.0.0.1/asp/printenv.html
  which, if working, will print out your environment variables.

=head2 WinME / 98 / 95 flock() workaround

For those on desktop Windows operation systems, Apache::ASP v2.25 and
later needs a special work around for the lack of flock() support
on these systems.  Please add this to your Apache httpd.conf to
fix this problem after mod_perl is installed:

  <Perl>
   *CORE::GLOBAL::flock = sub { 1 };
  </Perl>
  PerlModule  Apache::ASP

Please be sure to add this configuration before Apache::ASP is loaded
via PerlModule, or a PerlRequire statement.

=head2 Linux DSO Distributions

If you have a linux distribution, like a RedHat Linux server,
with an RPM style Apache + mod_perl, seriously consider building 
a static version of the httpd server yourself, not DSO.  
DSO is marked as experimental for mod_perl, and often does 
not work, resulting in "no request object" error messages,
and other oddities, and are terrible to debug, because of
the strange kinds of things that can go wrong.

=head2 Build Apache and mod_perl

For a quick build of apache, there is a script in the distribution at
./make_httpd/build_httpds.sh that can compile a statically linked
Apache with mod_ssl and mod_perl.  Just drop the sources into the 
make_httpd directory, configure the environments as appropriate,
and execute the script like this: 

 make_httpd> ./build_httpds.sh

You might also find helpful a couple items:

  Stas's mod_perl guide install section
  http://perl.apache.org/guide/install.html

  Apache Toolbox
  http://www.apachetoolbox.com/

People have been using Apache Toolbox to automate their 
complex builds with great success.

=head2 Quick Start

Once you have successfully built the Apache Web Server with mod_perl,
copy the ./site/eg/ directory from the Apache::ASP installation 
to your Apache document tree and try it out!  You must put "AllowOverride All"
in your httpd.conf <Directory> config section to let the .htaccess file in the 
./site/eg installation directory do its work.  If you want a starter
config file for Apache::ASP, just look at the .htaccess file in the 
./site/eg/ directory.

So, you might add this to your Apache httpd.conf file just to get 
the scripts in ./site/eg working, where $DOCUMENT_ROOT represents
the DocumentRoot config for your apache server:

  <Directory $DOCUMENT_ROOT/asp/eg >
    Options FollowSymLinks
    AllowOverride All
  </Directory>

To copy the entire site, including the examples, you might
do a raw directory copy as in:

  shell> cp -rpd ./site $DOCUMENT_ROOT/asp

So you could then reference the Apache::ASP docs at /asp/ at your site,
and the examples at /asp/eg/ .

This is not a good production configuration, because it is insecure
with the FollowSymLinks, and tells Apache to look for .htaccess 
which is bad for performance but it should be handy for getting 
started with development.

You will know that Apache::ASP is working normally if you 
can run the scripts in ./site/eg/ without any errors.  Common
problems can be found in the FAQ section.

=head1 CONFIG

You may use a <Files ...> directive in your httpd.conf 
Apache configuration file to make Apache::ASP start ticking.  Configure the
optional settings if you want, the defaults are fine to get started.  
The settings are documented below.  
Make sure Global is set to where your web applications global.asa is 
if you have one!

 PerlModule  Apache::ASP
 <Files ~ (\.asp)>    
   SetHandler  perl-script
   PerlHandler Apache::ASP
   PerlSetVar  Global .
   PerlSetVar  StateDir /tmp/asp
 </Files>

NOTE: do not use this for the examples in ./site/eg.  To get the 
examples working, check out the Quick Start section of INSTALL

You may use other Apache configuration tags like <Directory>,
<Location>, and <VirtualHost>, to separately define ASP
configurations, but using the <Files> tag is natural for
ASP application building because it lends itself naturally
to mixed media per directory.  For building many separate
ASP sites, you might want to use separate .htaccess files,
or <Files> tags in <VirtualHost> sections, the latter being
better for performance.

=head2 Core

=item Global

Global is the nerve center of an Apache::ASP application, in which
the global.asa may reside defining the web application's 
event handlers.

This directory is pushed onto @INC, so you will be able 
to "use" and "require" files in this directory, and perl modules 
developed for this application may be dropped into this directory, 
for easy use.

Unless StateDir is configured, this directory must be some 
writeable directory by the web server.  $Session and $Application 
object state files will be stored in this directory.  If StateDir
is configured, then ignore this paragraph, as it overrides the 
Global directory for this purpose.

Includes, specified with <!--#include file=somefile.inc--> 
or $Response->Include() syntax, may also be in this directory, 
please see section on includes for more information.

  PerlSetVar Global /tmp

=item GlobalPackage

Perl package namespace that all scripts, includes, & global.asa
events are compiled into.  By default, GlobalPackage is some
obscure name that is uniquely generated from the file path of 
the Global directory, and global.asa file.  The use of explicitly
naming the GlobalPackage is to allow scripts access to globals
and subs defined in a perl module that is included with commands like:

  in perl script: use Some::Package;
  in apache conf: PerlModule Some::Package

  PerlSetVar GlobalPackage Some::Package

=item UniquePackages

default 0.  Set to 1 to compile each script into its own perl package,
so that subroutines defined in one script will not collide with another.

By default, ASP scripts in a web application are compiled into the 
*same* perl package, so these scripts, their includes, and the 
global.asa events all share common globals & subroutines defined by each other.
The problem for some developers was that they would at times define a 
subroutine of the same name in 2+ scripts, and one subroutine definition would
redefine the other one because of the namespace collision.

  PerlSetVar UniquePackages 0

=item DynamicIncludes

default 0.  SSI file includes are normally inlined in the calling 
script, and the text gets compiled with the script as a whole. 
With this option set to TRUE, file includes are compiled as a
separate subroutine and called when the script is run.  
The advantage of having this turned on is that the code compiled
from the include can be shared between scripts, which keeps the 
script sizes smaller in memory, and keeps compile times down.

  PerlSetVar DynamicIncludes 0

=item IncludesDir

no defaults.  If set, this directory will also be used to look
for includes when compiling scripts.  By default the directory 
the script is in, and the Global directory are checked for includes.  

This extension was added so that includes could be easily shared
between ASP applications, whereas placing includes in the Global
directory only allows sharing between scripts in an application.

  PerlSetVar IncludesDir .

Also, multiple includes directories may be set by creating
a directory list separated by a semicolon ';' as in

  PerlSetVar IncludesDir ../shared;/usr/local/asp/shared

Using IncludesDir in this way creates an includes search
path that would look like ., Global, ../shared, /usr/local/asp/shared
The current directory of the executing script is checked first
whenever an include is specified, then the Global directory
in which the global.asa resides, and finally the IncludesDir 
setting.

=item NoCache

Default 0, if set to 1 will make it so that neither script nor
include compilations are cached by the server.  Using this configuration
will save on memory but will slow down script execution.  Please
see the TUNING section for other strategies on improving site performance.

  PerlSetVar NoCache 0

=head2 State Management

=item NoState

default 0, if true, neither the $Application nor $Session objects will
be created.  Use this for a performance increase.  Please note that 
this setting takes precedence over the AllowSessionState and
AllowApplicationState settings.

  PerlSetVar NoState 0

=item AllowSessionState

Set to 0 for no session tracking, 1 by default
If Session tracking is turned off, performance improves,
but the $Session object is inaccessible.

  PerlSetVar AllowSessionState 1    

Note that if you want to dissallow session creation
for certain non web browser user agents, like search engine
spiders, you can use an init handler like:

  PerlInitHandler "sub { $_[0]->dir_config('AllowSessionState', 0) }"

=item AllowApplicationState

Default 1.  If you want to leave $Application undefined, then set this
to 0, for a performance increase of around 2-3%.  Allowing use of 
$Application is less expensive than $Session, as there is more
work for the StateManager associated with $Session garbage collection
so this parameter should be only used for extreme tuning.

  PerlSetVar AllowApplicationState 1

=item StateDir

default $Global/.state.  State files for ASP application go to 
this directory.  Where the state files go is the most important
determinant in what makes a unique ASP application.  Different
configs pointing to the same StateDir are part of the same
ASP application.

The default has not changed since implementing this config directive.
The reason for this config option is to allow operating systems with caching
file systems like Solaris to specify a state directory separately
from the Global directory, which contains more permanent files.
This way one may point StateDir to /tmp/myaspapp, and make one's ASP
application scream with speed.

  PerlSetVar StateDir ./.state

=item StateManager

default 10, this number specifies the numbers of times per SessionTimeout
that timed out sessions are garbage collected.  The bigger the number,
the slower your system, but the more precise Session_OnEnd's will be 
run from global.asa, which occur when a timed out session is cleaned up,
and the better able to withstand Session guessing hacking attempts.
The lower the number, the faster a normal system will run.  

The defaults of 20 minutes for SessionTimeout and 10 times for 
StateManager, has dead Sessions being cleaned up every 2 minutes.

  PerlSetVar StateManager 10

=item StateDB

default SDBM_File, this is the internal database used for state
objects like $Application and $Session.  Because an SDBM_File %hash 
has a limit on the size of a record key+value pair, usually 1024 bytes,
you may want to use another tied database like DB_File or
MLDBM::Sync::SDBM_File.

With lightweight $Session and $Application use, you can get 
away with SDBM_File, but if you load it up with complex data like
  $Session{key} = { # very large complex object }
you might max out the 1024 limit.

Currently StateDB can be: SDBM_File, MLDBM::Sync::SDBM_File,
DB_File, and GDBM_File.  Please let me know if you would like to
add any more to this list.

As of version .18, you may change this setting in a live production
environment, and new state databases created will be of this format.
With a prior version if you switch to a new StateDB, you would want to 
delete the old StateDir, as there will likely be incompatibilities between
the different database formats, including the way garbage collection
is handled.

  PerlSetVar StateDB SDBM_File

=item StateCache

Deprecated as of 2.23.  There is no equivalent config for
the functionality this represented from that version on.
The 2.23 release represented a significant rewrite
of the state management, moving to MLDBM::Sync for its
subsystem.

=item StateSerializer

default Data::Dumper, you may set this to Storable for 
faster serialization and storage of data into state objects.
This is particularly useful when storing large objects in
$Session and $Application, as the Storable.pm module has a faster
implementation of freezing and thawing data from and to
perl structures.  Note that if you are storing this much
data in your state databases, you may want to use 
DB_File since it does not have the default 1024 byte limit 
that SDBM_File has on key/value lengths.

This configuration setting may be changed in production
as the state database's serializer type is stored
in the internal state manager which will always use 
Data::Dumper & SDBM_File to store data.

  PerlSetVar StateSerializer Data::Dumper

=head2 Sessions

=item CookiePath

URL root that client responds to by sending the session cookie.
If your asp application falls under the server url "/asp", 
then you would set this variable to /asp.  This then allows
you to run different applications on the same server, with
different user sessions for each application.

  PerlSetVar CookiePath /   

=item CookieDomain

Default 0, this NON-PORTABLE configuration will allow sessions to span
multiple web sites that match the same domain root.  This is useful if
your web sites are hosted on the same machine and can share the same
StateDir configuration, and you want to shared the $Session data 
across web sites.  Whatever this is set to, that will add a 

  ; domain=$CookieDomain

part to the Set-Cookie: header set for the session-id cookie.

  PerlSetVar CookieDomain .your.global.domain

=item SessionTimeout

Default 20 minutes, when a user's session has been inactive for this
period of time, the Session_OnEnd event is run, if defined, for 
that session, and the contents of that session are destroyed.

  PerlSetVar SessionTimeout 20 

=item SecureSession

default 0.  Sets the secure tag for the session cookie, so that the cookie
will only be transmitted by the browser under https transmissions.

  PerlSetVar SecureSession 1

=item ParanoidSession

default 0.  When true, stores the user-agent header of the browser 
that creates the session and validates this against the session cookie presented.
If this check fails, the session is killed, with the rationale that 
there is a hacking attempt underway.

This config option was implemented to be a smooth upgrade, as
you can turn it off and on, without disrupting current sessions.  
Sessions must be created with this turned on for the security to take effect.

This config option is to help prevent a brute force cookie search from 
being successful. The number of possible cookies is huge, 2^128, thus making such
a hacking attempt VERY unlikely.  However, on the off chance that such
an attack is successful, the hacker must also present identical
browser headers to authenticate the session, or the session will be
destroyed.  Thus the User-Agent acts as a backup to the real session id.
The IP address of the browser cannot be used, since because of proxies,
IP addresses may change between requests during a session.

There are a few browsers that will not present a User-Agent header.
These browsers are considered to be browsers of type "Unknown", and 
this method works the same way for them.

Most people agree that this level of security is unnecessary, thus
it is titled paranoid :)

  PerlSetVar ParanoidSession 0

=item SessionSerialize

default 0, if true, locks $Session for duration of script, which
serializes requests to the $Session object.  Only one script at
a time may run, per user $Session, with sessions allowed.

Serialized requests to the session object is the Microsoft ASP way, 
but is dangerous in a production environment, where there is risk
of long-running or run-away processes.  If these things happen,
a session may be locked for an indefinite period of time.  A user
STOP button should safely quit the session however.

  PerlSetVar SessionSerialize 0

=item SessionCount

default 0, if true enables the $Application->SessionCount API
which returns how many sessions are currently active in 
the application.  This config was created 
because there is a performance hit associated with this
count tracking, so it is disabled by default.

  PerlSetVar SessionCount 1

=head2 Cookieless Sessions

=item SessionQueryParse

default 0, if true, will automatically parse the $Session
session id into the query string of each local URL found in the 
$Response buffer.  For this setting to work therefore, 
buffering must be enabled.  This parsing will only occur
when a session cookie has not been sent by a browser, so the 
first script of a session enabled site, and scripts viewed by 
web browsers that have cookies disabled will trigger this behavior.

Although this runtime parsing method is computationally 
expensive, this cost should be amortized across most users
that will not need this URL parsing.  This is a lazy programmer's
dream.  For something more efficient, look at the SessionQuery
setting.  For more information about this solution, please 
read the SESSIONS section.

  PerlSetVar SessionQueryParse 0

=item SessionQueryParseMatch

default 0, set to a regexp pattern that matches all URLs that you 
want to have SessionQueryParse parse in session ids.  By default
SessionQueryParse only modifies local URLs, but if you name
your URLs of your site with absolute URLs like http://localhost
then you will need to use this setting.  So to match 
http://localhost URLs, you might set this pattern to 
^http://localhost.  Note that by setting this config,
you are also setting SessionQueryParse.

  PerlSetVar SessionQueryParseMatch ^https?://localhost

=item SessionQuery

default 0, if set, the session id will be initialized from
the $Request->QueryString if not first found as a cookie.
You can use this setting coupled with the 

  $Server->URL($url, \%params) 

API extension to generate local URLs with session ids in their
query strings, for efficient cookieless session support.
Note that if a browser has cookies disabled, every URL
to any page that needs access to $Session will need to
be created by this method, unless you are using SessionQueryParse
which will do this for you automatically.

  PerlSetVar SessionQuery 0

=item SessionQueryMatch

default 0, set to a regexp pattern that will match
URLs for $Server->URL() to add a session id to.  SessionQuery
normally allows $Server->URL() to add session ids just to 
local URLs, so if you use absolute URL references like 
http://localhost/ for your web site, then just like 
with SessionQueryParseMatch, you might set this pattern
to ^http://localhost

If this is set, then you don't need to set SessionQuery,
as it will be set automatically.

  PerlSetVar SessionQueryMatch ^http://localhost

=item SessionQueryForce

default 0, set to 1 if you want to disallow the use of cookies
for session id passing, and only allow session ids to be passed
on the query string via SessionQuery and SessionQueryParse settings.

  PerlSetVar SessionQueryForce 1

=head2 Developer Environment

=item UseStrict

default 0, if set to 1, will compile all scripts, global.asa
and includes with "use strict;" inserted at the head of 
the file, saving you from the painful process of strictifying
code that was not strict to begin with.

Because of how essential "use strict" programming is in
a mod_perl environment, this default might be set to 1 
one day, but this will be up for discussion before that
decision is made.

Note too that errors triggered by "use strict" are
now captured as part of the normal Apache::ASP error 
handling when this configuration is set, otherwise
"use strict" errors will not be handled properly, so
using UseStrict is better than your own "use strict"
statements.

PerlSetVar UseStrict 1

=item Debug

1 for server log debugging, 2 for extra client html output,
3 for microtimes logged. Use 1 for production debugging, 
use 2 or 3 for development.  Turn off if you are not 
debugging.  These settings activate $Response->Debug().

  PerlSetVar Debug 2	

If Debug 3 is set and Time::HiRes is installed, microtimes
will show up in the log, and also calculate the time
between one $Response->Debug() and another, so good for a
quick benchmark when you glance at the logs.

  PerlSetVar Debug 3

If you would like to enable system level debugging, set
Debug to a negative value.  So for system level debugging,
but no output to browser:

  PerlSetVar Debug -1

=item DebugBufferLength

Default 100, set this to the number of bytes of the 
buffered output's tail you want to see when an error occurs
and Debug 2 or MailErrorsTo is set, and when 
BufferingOn is enabled.  

With buffering the script output will not naturally show 
up when the script errors, as it has been buffered by the 
$Response object.  It helps to see where in the script
output an error halted the script, so the last bytes of 
the buffered output are included with the rest of 
the debugging information.  

For a demo of this functionality, try the 
./site/eg/syntax_error.htm script, and turn buffering on.

=item PodComments

default 1.  With pod comments turned on, perl pod style comments
and documentation are parsed out of scripts at compile time.
This make for great documentation and a nice debugging tool,
and it lets you comment out perl code and html in blocks.  
Specifically text like this:

 =pod
 text or perl code here
 =cut 

will get ripped out of the script before compiling.  The =pod and =cut 
perl directives must be at the beginning of the line, and must
be followed by the end of the line.

  PerlSetVar PodComments 1

=item CollectionItem

Enables PerlScript syntax like:

  $Request->Form('var')->Item;
  $Request->Form('var')->Item(1);
  $Request->Form('var')->Count;

Old PerlScript syntax, enabled with

  use Win32::OLE qw(in valof with OVERLOAD);

is like native syntax

  $Request->Form('var');

Only in Apache::ASP, can the above be written as:

  $Request->{Form}{var};

which you would do if you _really_ needed the speed.

=head2 XML / XSLT

=item XMLSubsMatch

default not defined, set to some regexp pattern
that will match all XML and HTML tags that you want
to have perl subroutines handle.  The is Apache::ASP's
custom tag technology, and can be used to create
powerful extensions to your XML and HTML rendering.

Please see XML/XSLT section for instructions on its use.

  PerlSetVar XMLSubsMatch my:[\w\-]+

=item XMLSubsStrict

default 0, when set XMLSubs will only take arguments
that are properly formed XML tag arguments like:

 <my:sub arg1="value" arg2="value" />

By default, XMLSubs accept arbitrary perl code as
argument values:

 <my:sub arg1=1+1 arg2=&perl_sub()/>

which is not always wanted or expected.  Set
XMLSubsStrict to 1 if this is the case.

  PerlSetVar XMLSubsStrict 1

=item XMLSubsPerlArgs

default 1, when set attribute values will be interpreted
as raw perl code so that these all would execute as one
would expect:

 <my:xmlsubs arg='1' arg2="2" arg3=$value arg4="1 $value" />

With the 2.45 release, 0 may be set for this configuration
or a more ASP style variable interpolation:

 <my:xmlsubs arg='1' arg2="2" args3="<%= $value %>" arg4="1 <%= $value %>" />

This configuration is being introduced experimentally in version 2.45,
as it will become the eventual default in the 3.0 release.

  PerlSetVar XMLSubsPerlArgs Off

=item XSLT

default not defined, if set to a file, ASP scripts will
be regarded as XML output and transformed with the given
XSL file with XML::XSLT.  This XSL file will also be
executed as an ASP script first, and its output will be
the XSL data used for the transformation.  This XSL file
will be executed as a dynamic include, so may be located
in the current directory, Global, or IncludesDir.

Please see the XML/XSLT section for an explanation of its
use.

  PerlSetVar XSLT template.xsl

=item XSLTMatch

default .*, if XSLT is set by default all ASP scripts 
will be XSL transformed by the specified XSL template.
This regexp setting will tell XSLT which file names to 
match with doing XSL transformations, so that regular
HTML ASP scripts and XML ASP scripts can be configured
with the same configuration block.  Please see
./site/eg/.htaccess for an example of its use.

  PerlSetVar XSLTMatch \.xml$

=item XSLTParser

default XML::XSLT, determines which perl module to use for 
XSLT parsing.  This is a new config as of 2.11.
Also supported is XML::Sablotron which does not
handle XSLT with the exact same output, but is about
10 times faster than XML::XSLT.  XML::LibXSLT may
also be used as of version 2.29, and seems to be
about twice again as fast as XML::Sablotron,
and a very complete XSLT implementation.

  PerlSetVar XSLTParser XML::XSLT
  PerlSetVar XSLTParser XML::Sablotron
  PerlSetVar XSLTParser XML::LibXSLT

=item XSLTCache

Activate XSLT file based caching through CacheDB, CacheDir,
and CacheSize settings.  This gives cached XSLT performance
near AxKit and greater than Cocoon.  XSLT caches transformations
keyed uniquely by XML & XSLT inputs.

  PerlSetVar XSLTCache 1

=item XSLTCacheSize

as of version 2.11, this config is no longer supported.

=head2 Caching

The output caching layer is a file dbm based output cache that runs
on top of the MLDBM::Sync so inherits its performance characteristics.  
With CacheDB set to MLDBM::Sync::SDBM_File, the cache layer is 
very fast at caching entries up to 20K in size, but for greater 
cached items, you should set CacheDB to another dbm like DB_File 
or GDBM_File.

In order for the cache layer
to function properly, whether for $Response->Include() output
caching, see OBJECTS, or XSLT caching, see XML/XSLT, then
Apache::ASP must be loaded in the parent httpd like so:

  # httpd.conf
  PerlModule Apache::ASP
    -- or --
  <Perl>
    use Apache::ASP;
  </Perl>

The cache layer automatically expires entries upon
server restart, but for this to work, a $ServerID
must be computed when the Apache::ASP module gets
loaded to store in each cached item.  Without the 
above done, each child httpd process will get its
own $ServerID, so caching will not work at all.

This said, output caching will not work in raw CGI mode,
just running under mod_perl.

=item CacheDB

Like StateDB, sets dbm format for caching.  Since SDBM_File
only support key/values pairs of around 1K max in length,
the default for this is MLDBM::Sync::SDBM_File, which is very
fast for < 20K output sizes.  For caching larger data than 20K,
DB_File or GDBM_File are probably better to use.

  PerlSetVar CacheDB MLDBM::Sync::SDBM_File

=begin html

Here are some benchmarks about the CacheDB when used 
with caching output from $Response->Include(\%cache)
running on a Linux 2.2.14 dual PIII-450. 
The variables are output size being cached & the CacheDB used,
the default being MLDBM::Sync::SDBM_File. 

<table class="noescape" border="0">
<tr><th>CacheDB</th><th>Output Cached</th><th>Operation</th><th>Ops/sec</th></tr>
<tr><td>MLDBM::Sync::SDBM_File</td>	<td>3200 bytes</td>	<td>read</td>	<td>177</td></tr>
<tr><td>DB_File</td>			<td>3200 bytes</td>	<td>read</td>	<td>59</td></tr>
<tr><td>MLDBM::Sync::SDBM_File</td>	<td>32000 bytes</td>	<td>read</td>	<td>42</td></tr>
<tr><td>DB_File</td>			<td>32000 bytes</td>	<td>read</td>	<td>53</td></tr>
<tr><td>MLDBM::Sync::SDBM_File</td>	<td>3200 bytes</td>	<td>write</td>	<td>42</td></tr>
<tr><td>DB_File</td>			<td>3200 bytes</td>	<td>write</td>	<td>39</td></tr>
</table>

=end html

For your own benchmarks to test the relative speeds of the
various DBMs under MLDBM::Sync, which is used by CacheDB,
you may run the ./bench/bench_sync.pl script from the 
MLDBM::Sync distribution on your system.

=item CacheDir

By default, the cache directory is at StateDir/cache,
but CacheDir can be used to set the StateDir value for 
caching purposes.  One may want the CacheDir separate
from StateDir for example StateDir might be a centrally
network mounted file system, while CacheDir might be
a local file cache.

  PerlSetVar CacheDir /tmp/asp_demo

On a system like Solaris where there is a RAM disk 
mounted on the system like /tmp, I could put the CacheDir
there.  On a system like Linux where files are cached
pretty well by default, this is less important.

=item CacheSize

By default, this is 10M of data per cache.  When any cache, 
like the XSLTCache, reaches this limit, the cache will be purged 
by deleting the cached dbm files entirely.  This is better for 
long term running of dbms than deleting individual records, 
because dbm formats will often degrade in performance with 
lots of insert & deletes.

Units of M, K, and B are supported for megabytes, kilobytes, and bytes,
with the default unit being B, so the following configs all mean the
same thing;

  PerlSetVar CacheSize 10M
  PerlSetVar CacheSize 10240K
  PerlSetVar CacheSize 10485760B
  PerlSetVar CacheSize 10485760

There are 2 caches currently, the XSLTCache, and the
Response cache, the latter which is currently invoked
for caching output from includes with special syntax.
See $Response->Include() for more info on the Response cache.

=head2 Miscellaneous

=item AuthServerVariables

default 0. If you are using basic auth and would like 
$Request->ServerVariables set like AUTH_TYPE, AUTH_USER, 
AUTH_NAME, REMOTE_USER, & AUTH_PASSWD, then set this and
Apache::ASP will initialize these values from Apache->*auth* 
commands.  Use of these environment variables keeps applications
cross platform compatible as other servers set these too
when performing basic 401 auth.

  PerlSetVar AuthServerVariables 0

=item BufferingOn

default 1, if true, buffers output through the response object.
$Response object will only send results to client browser if
a $Response->Flush() is called, or if the asp script ends.  Lots of 
output will need to be flushed incrementally.

If false, 0, the output is immediately written to the client,
CGI style.  There will be a performance hit server side if output
is flushed automatically to the client, but is probably small.

I would leave this on, since error handling is poor, if your asp 
script errors after sending only some of the output.

  PerlSetVar BufferingOn 1

=item InodeNames

Default 0. Set to 1 to uses a stat() call on scripts and includes to
derive subroutine namespace based on device and inode numbers. In case of 
multiple symbolic links pointing to the same script this will result 
in the script being compiled only once. Use only on unix flavours
which support the stat() call that know about device and inode 
numbers.

  PerlSetVar InodeNames 1

=item RequestParams

Default 0, if set creates $Request->Params object with combined 
contents of $Request->QueryString and $Request->Form.  This
is for developer convenience simlar to CGI.pm's param() method.

  PerlSetVar RequestParams 1

=item RequestBinaryRead

Default On, if set to Off will not read POST data into $Request->Form().

One potential reason for configuring this to Off might be to initialize the Apache::ASP
object in an Apache handler phase earlier than the normal PerlRequestHandler
phase, so that it does not interfere with normal reading of POST data later
in the request.

  PerlSetVar RequestBinaryRead On

=item StatINC

default 0, if true, reloads perl libraries that have changed
on disk automatically for ASP scripts.  If false, the www server
must be restarted for library changes to take effect.

A known bug is that any functions that are exported, e.g. confess 
Carp qw(confess), will not be refreshed by StatINC.  To refresh
these, you must restart the www server.  

This setting should be used in development only because it is so slow.
For a production version of StatINC, see StatINCMatch.

  PerlSetVar StatINC 1

=item StatINCMatch

default undef, if defined, it will be used as a regular expression
to reload modules that match as in StatINC.  This is useful because
StatINC has a very high performance penalty in production, so if
you can narrow the modules that are checked for reloading each
script execution to a handful, you will only suffer a mild performance 
penalty.

The StatINCMatch setting should be a regular expression like: Struct|LWP
which would match on reloading Class/Struct.pm, and all the LWP/.*
libraries.

If you define StatINCMatch, you do not need to define StatINC.

  PerlSetVar StatINCMatch .*

=item StatScripts

default 1, if set to 0, changed scripts, global.asa, and includes
will not be reloaded.  Coupled with Apache mod_perl startup and restart
handlers executing Apache::ASP->Loader() for your application
this allows your application to be frozen, and only reloaded on the 
next server restart or stop/start.

There are a few advantages for not reloading scripts and modules
in production.  First there is a slight performance improvement
by not having to stat() the script, its includes and the global.asa
every request.  

From an application deployment standpoint, you
also gain the ability to deploy your application as a 
snapshot taken when the server starts and restarts.
This provides you with the reassurance that during a
production server update from development sources, you 
do not have to worry with sources being used for the 
wrong libraries and such, while they are all being 
copied over.

Finally, though you really should not do this, you can
work on a live production application, with a test server
reloading changes, but your production server does see
the changes until you restart or stop/start it.  This 
saves your public from syntax errors while you are just
doing a quick bug fix.

  PerlSetVar StatScripts 1

=item SoftRedirect

default 0, if true, a $Response->Redirect() does not end the 
script.  Normally, when a Redirect() is called, the script
is ended automatically.  SoftRedirect 1, is a standard
way of doing redirects, allowing for html output after the 
redirect is specified.

  PerlSetVar SoftRedirect 0

=item Filter

On/Off, default Off.  With filtering enabled, you can take advantage of 
full server side includes (SSI), implemented through Apache::SSI.  
SSI is implemented through this mechanism by using Apache::Filter.  
A sample configuration for full SSI with filtering is in the 
./site/eg/.htaccess file, with a relevant example script ./site/eg/ssi_filter.ssi.

You may only use this option with modperl v1.16 or greater installed
and PERL_STACKED_HANDLERS enabled.  Filtering may be used in 
conjunction with other handlers that are also "filter aware".
If in doubt, try building your mod_perl with 

  perl Makefile.PL EVERYTHING=1

With filtering through Apache::SSI, you should expect near a
a 20% performance decrease.

  PerlSetVar Filter Off

=item CgiHeaders

default 0.  When true, script output that looks like HTTP / CGI
headers, will be added to the HTTP headers of the request.
So you could add:
  Set-Cookie: test=message

  <html>...
to the top of your script, and all the headers preceding a newline
will be added as if with a call to $Response->AddHeader().  This
functionality is here for compatibility with raw cgi scripts,
and those used to this kind of coding.

When set to 0, CgiHeaders style headers will not be parsed from the 
script response.

  PerlSetVar CgiHeaders 0

=item Clean

default 0, may be set between 1 and 9.  This setting determine how much
text/html output should be compressed.  A setting of 1 strips mostly
white space saving usually 10% in output size, at a performance cost
of less than 5%.  A setting of 9 goes much further saving anywhere
25% to 50% typically, but with a performance hit of 50%.

This config option is implemented via HTML::Clean.  Per script
configuration of this setting is available via the $Response->{Clean}
property, which may also be set between 0 and 9.

  PerlSetVar Clean 0

=item CompressGzip

default 0, if true will gzip compress HTML output on the
fly if Compress::Zlib is installed, and the client browser
supports it.  Depending on the HTML being compressed, 
the client may see a 50% to 90% reduction in HTML output.
I have seen 40K of HTML squeezed down to just under 6K.
This will come at a 5%-20% hit to CPU usage per request
compressed.

Note there are some cases when a browser says it will accept
gzip encoding, but then not render it correctly.  This
behavior has been seen with IE5 when set to use a proxy but 
not using a proxy, and the URL does not end with a .html or .htm.
No work around has yet been found for this case so use at your 
own risk.

  PerlSetVar CompressGzip 1

=item FormFill

default 0, if true will auto fill HTML forms with values
from $Request->Form().  This functionality is provided
by use of HTML::FillInForm.  For more information please
see "perldoc HTML::FillInForm", and the 
example ./site/eg/formfill.asp.  

This feature can be enabled on a per form basis at runtime
with $Response->{FormFill} = 1

  PerlSetVar FormFill 1

=item TimeHiRes

default 0, if set and Time::HiRes is installed, will do 
sub second timing of the time it takes Apache::ASP to process
a request.  This will not include the time spent in the 
session manager, nor modperl or Apache, and is only a 
rough approximation at best.

If Debug is set also, you will get a comment in your
HTML output that indicates the time it took to process
that script.

If system debugging is set with Debug -1 or -2, you will
also get this time in the Apache error log with the 
other system messages.

=head2 Mail Administration

Apache::ASP has some powerful administrative email
extensions that let you sleep at night, knowing full well
that if an error occurs at the web site, you will know
about it immediately.  With these features already enabled,
it was also easy to provide the $Server->Mail(\%mail) API 
extension which you can read up about in the OBJECTS section.

=item MailHost

The mail host is the smtp server that the below Mail* config directives
will use when sending their emails.  By default Net::SMTP uses
smtp mail hosts configured in Net::Config, which is set up at
install time, but this setting can be used to override this config.

The mail hosts specified in the Net::Config file will be used as
backup smtp servers to the MailHost specified here, should this
primary server not be working.

  PerlSetVar MailHost smtp.yourdomain.com.foobar

=item MailFrom

Default NONE, set this to specify the default mail address placed 
in the From: mail header for the $Server->Mail() API extension, 
as well as MailErrorsTo and MailAlertTo.

  PerlSetVar MailFrom youremail@yourdomain.com.foobar

=item MailErrorsTo

No default, if set, ASP server errors, error code 500, that result
while compiling or running scripts under Apache::ASP will automatically
be emailed to the email address set for this config.  This allows
an administrator to have a rapid response to user generated server
errors resulting from bugs in production ASP scripts.  Other errors, such 
as 404 not found will be handled by Apache directly.

An easy way to see this config in action is to have an ASP script which calls
a die(), which generates an internal ASP 500 server error.

The Debug config of value 2 and this setting are mutually exclusive,
as Debug 2 is a development setting where errors are displayed in the browser,
and MailErrorsTo is a production setting so that errors are silently logged
and sent via email to the web admin.

  PerlSetVar MailErrorsTo youremail@yourdomain.com

=item MailAlertTo

The address configured will have an email sent on any ASP server error 500,
and the message will be short enough to fit on a text based pager.  This
config setting would be used to give an administrator a heads up that a www
server error occurred, as opposed to MailErrorsTo would be used for debugging
that server error.

This config does not work when Debug 2 is set, as it is a setting for
use in production only, where Debug 2 is for development use.

  PerlSetVar MailAlertTo youremail@yourdomain.com

=item MailAlertPeriod

Default 20 minutes, this config specifies the time in minutes over 
which there may be only one alert email generated by MailAlertTo.
The purpose of MailAlertTo is to give the admin a heads up that there
is an error at the www server.  MailErrorsTo is for to aid in speedy 
debugging of the incident.

  PerlSetVar MailAlertPeriod 20

=head2 File Uploads

=item FileUploadMax

default 0, if set will limit file uploads to this
size in bytes.  This is currently implemented by 
setting $CGI::POST_MAX before handling the file
upload.  Prior to this, a developer would have to
hardcode a value for $CGI::POST_MAX to get this 
to work.

  PerlSetVar 100000

=item FileUploadTemp

default 0, if set will leave a temp file on disk during the request, 
which may be helpful for processing by other programs, but is also
a security risk in that other users on the operating system could 
potentially read this file while the script is running. 

The path to the temp file will be available at
$Request->{FileUpload}{$form_field}{TempFile}.
The regular use of file uploads remains the same
with the <$filehandle> to the upload at 
$Request->{Form}{$form_field}.  Please see the CGI section
for more information on file uploads, and the $Request
section in OBJECTS.

  PerlSetVar FileUploadTemp 0

=head1 SYNTAX

=head2 General

ASP embedding syntax allows one to embed code in html in 2 simple ways.
The first is the <% xxx %> tag in which xxx is any valid perl code.
The second is <%= xxx %> where xxx is some scalar value that will
be inserted into the html directly.  An easy print.

  A simple asp page would look like:
  
  <!-- sample here -->
  <html>
  <body>
  For loop incrementing font size: <p>
  <% for(1..5) { %>
	<!-- iterated html text -->
	<font size="<%=$_%>" > Size = <%=$_%> </font> <br>
  <% } %>
  </body>
  </html>
  <!-- end sample here -->

Notice that your perl code blocks can span any html.  The for loop
above iterates over the html without any special syntax.

=head2 XMLSubs

XMLSubs allows a developer to define custom handlers for
HTML & XML tags, which can extend the natural syntax
of the ASP environment.  Configured like:

  PerlSetVar XMLSubsMatch site:\w+

A simple tag like:

  <site:header title="Page Title" />

can be constructed that could translate into:

  sub site::header {
      my $args = shift;
      print "<html><head><title>$args->{title}</title></head>\n";
      print "<body bgcolor=white>\n";
  }

Better yet, one can use this functionality to trap
and post process embedded HTML & XML like:

  <site:page title="Page Title">
    ... some HTML here ...
  </site:page>

and then:

  sub site::page {
    my($args, $html) = @_;
    &site::header($args);
    $main::Response->Write($html);
    $main::Response->Write("</body></html>");
  }

Though this could be used to fully render XML 
documents, it was not built for this purpose, but
to add powerful tag extensions to HTML development
environments.  For full XML rendering, you ought
to try an XSLT approach, also supported by Apache::ASP.

=head2 Editors

As Apache::ASP supports a mixing of perl and HTML,
any editor which supports development of one or the 
other would work well.  The following editors are
known to work well for developing Apache::ASP web sites:

 * Emacs, in perl or HTML modes.  For a mmm-mode config
   that mixes HTML & perl modes in a single buffer, check 
   out the editors/mmm-asp-perl.el file in distribution.

 * Microsoft Frontpage

 * Vim, special syntax support with editors/aasp.vim file in distribution.

 * UltraEdit32 ( http://www.ultraedit.com/ ) has syntax highlighting, 
   good macros and a configurable wordlist (so one can have syntax 
   highlighting both for Perl and HTML).

Please feel free to suggest your favorite development
environment for this list.

=head1 EVENTS

=head2 Overview

The ASP platform allows developers to create Web Applications.
In fulfillment of real software requirements, ASP allows 
event-triggered actions to be taken, which are defined in
a global.asa file.  The global.asa file resides in the 
Global directory, defined as a config option, and may
define the following actions:

	Action			Event
	------			------
        Script_OnStart *	Beginning of Script execution
        Script_OnEnd *		End of Script execution
        Script_OnFlush *	Before $Response being flushed to client.
        Script_OnParse *        Before script compilation
	Application_OnStart	Beginning of Application
	Application_OnEnd	End of Application
	Session_OnStart		Beginning of user Session.
	Session_OnEnd		End of user Session.

  * These are API extensions that are not portable, but were
    added because they are incredibly useful

These actions must be defined in the $Global/global.asa file
as subroutines, for example:

  sub Session_OnStart {
      $Application->{$Session->SessionID()} = started;
  }

Sessions are easy to understand.  When visiting a page in a
web application, each user has one unique $Session.  This 
session expires, after which the user will have a new
$Session upon revisiting.

A web application starts when the user visits a page in that
application, and has a new $Session created.  Right before
the first $Session is created, the $Application is created.
When the last user $Session expires, that $Application 
expires also.  For some web applications that are always busy,
the Application_OnEnd event may never occur.

=head2 Script_OnStart & Script_OnEnd

The script events are used to run any code for all scripts
in an application defined by a global.asa.  Often, you would
like to run the same code for every script, which you would
otherwise have to add by hand, or add with a file include,
but with these events, just add your code to the global.asa,
and it will be run.  

There is one caveat.  Code in Script_OnEnd is not guaranteed 
to be run when $Response->End() is called, since the program
execution ends immediately at this event.  To always run critical
code, use the API extension:

	$Server->RegisterCleanup()

=head2 Session_OnStart

Triggered by the beginning of a user's session, Session_OnStart
gets run before the user's executing script, and if the same
session recently timed out, after the session's triggered Session_OnEnd.

The Session_OnStart is particularly useful for caching database data,
and avoids having the caching handled by clumsy code inserted into
each script being executed.

=head2 Session_OnEnd

Triggered by a user session ending, Session_OnEnd can be useful
for cleaning up and analyzing user data accumulated during a session.

Sessions end when the session timeout expires, and the StateManager
performs session cleanup.  The timing of the Session_OnEnd does not
occur immediately after the session times out, but when the first 
script runs after the session expires, and the StateManager allows
for that session to be cleaned up.  

So on a busy site with default SessionTimeout (20 minutes) and 
StateManager (10 times) settings, the Session_OnEnd for a particular 
session should be run near 22 minutes past the last activity that Session saw.
A site infrequently visited will only have the Session_OnEnd run
when a subsequent visit occurs, and theoretically the last session
of an application ever run will never have its Session_OnEnd run.

Thus I would not put anything mission-critical in the Session_OnEnd,
just stuff that would be nice to run whenever it gets run.

=head2 Script_OnFlush

API extension. This event will be called prior to flushing
the $Response buffer to the web client.  At this time,
the $Response->{BinaryRef} buffer reference may be used to modify 
the buffered output at runtime to apply global changes to scripts 
output without having to modify all the scripts.

 sub Script_OnFlush {
   my $ref = $Response->{BinaryRef};
   $$ref =~ s/\s+/ /sg; # to strip extra white space
 }

Check out the ./site/eg/global.asa for an example of its use.

=head2 Script_OnParse

This event allows one to set up a source filter on the script text,
allowing one to change the script on the fly before the compilation
stage occurs.  The script text is available in the $Server->{ScriptRef}
scalar reference, and can be accessed like so:

 sub Script_OnParse {
   my $code = $Server->{ScriptRef}
   $$code .= " ADDED SOMETHING ";
 }

=head2 Application_OnStart

This event marks the beginning of an ASP application, and 
is run just before the Session_OnStart of the first Session
of an application.  This event is useful to load up
$Application with data that will be used in all user sessions.

=head2 Application_OnEnd

The end of the application is marked by this event, which
is run after the last user session has timed out for a 
given ASP application.  

=head2 Server_OnStart ( pseudo-event )

Some might want something like a Server_OnStart event, where
some code gets runs when the web server starts.  In mod_perl,
this is easy to achieve outside of the scope of an ASP
application, by putting some initialization code into
a <Perl> section in the httpd.conf file.  Initializations
that you would like to be shared with the child httpds are
particularly useful, one such being the Apache::ASP->Loader() 
routine which you can read more about in the TUNING section -
Precompile Scripts subsection. It is could be called like:

  # httpd.conf
  <Perl>
     Apache::ASP->Loader($path, $pattern, %config)
  </Perl>

So a <Perl> section is your Server_OnStart routine!

=head2 mod_perl handlers

If one wants to extend one's environment with mod_perl
handlers, Apache::ASP does not stop this.  Basic
use of Apache::ASP in fact only involves the content
handler phase of mod_perl's PerlHandler, like

  SetHandler perl-script
  PerlModule Apache::ASP
  PerlHandler Apache::ASP 

But mod_perl allows for direct access to many more
Apache event stages, for full list try "perldoc mod_perl"
or buy the mod_perl Eagle book.  Some commonly used ones are:

  PerlInitHandler
  PerlTransHandler
  PerlFixupHandler
  PerlHandler
  PerlLogHandler
  PerlCleanupHandler

For straight Apache::ASP programming, there are some 
equivalents, say Script_OnStart event instead of Init/Fixup
stages, or $Server->RegisterCleanup() for Log/Cleanup stages,
but you can do things in the mod_perl handlers that you 
cannot do in Apache::ASP, especially if you want to handle
all files globally, and not just ASP scripts.

For many Apache::* modules for use with mod_perl, of which
Apache::ASP is just one, check out
http://perl.apache.org/src/apache-modlist.html

To gain access to the ASP objects like $Session outside
in a non-PerlHandler mod_perl handler, you may use this API:
  
  my $ASP = Apache::ASP->new($r); # $r is Apache->request object

as in this possible Authen handler:

  <Perl>
    use Apache::ASP;
    sub My::Auth::handler {
      my $r = shift;
      my $ASP = Apache::ASP->new($r) 
      my $Session = $ASP->Session;
    }
  </Perl>

Here are some examples of do-it-yourself mod_perl
handler programming...

 === Forbid Bad HSlide User Agent ===

 # httpd.conf
 PerlAccessHandler My::Access
 <Perl>
   sub My::Access::handler {
     my $r = shift;
     if($r->headers_in->{'USER_AGENT'} =~ /HSlide/) {
	 403;
     } else {
	 200;
     }
   }
 </Perl>

 === Runtime Path Parsing ===

This example shows how one might take an arbitrary
URL path /$path/$file.asp, and turn that into a runtime 
config for your site, so your scripts get executed
always in your sites DocumentRoot.

 INPUT URL /SomeCategory/
 OUTPUT
  Script: index.asp
  $Server->Config('PATH') eq '/SomeCategory'

 INPUT URL /SomeCategory/index.asp
 OUTPUT
  Script: index.asp
  $Server->Config('PATH') eq '/SomeCategory'

 INPUT URI /index.asp
 OUTPUT
  Script: index.asp
  $Server->Config('PATH') eq ''

 # httpd.conf
 PerlTransHandler My::Init
 use lib qw( $custom_perllib );

 # $custom_perllib/My/Init.pm
 package My::Init;
 use strict;
 use Apache::Constants qw(:common);
 sub handler {
    my $r = shift;

    my $uri = $r->uri || '/';
    unless($uri =~ m|^(.*)(/([^/.]+\.[\w]+)?)$|i) {
	warn("can't parse uri $uri");
	return DECLINED;
    }
    $uri = $2;
    my $PATH = $1 || '';
    $r->dir_config('PATH', $PATH);

    if($uri eq '/') {
	$uri = '/index.asp';
    }

    $r->uri($uri);
    $r->filename($r->document_root.$uri);

    DECLINED;
 }

 1;

=head1 OBJECTS

The beauty of the ASP Object Model is that it takes the
burden of CGI and Session Management off the developer, 
and puts them in objects accessible from any
ASP script & include.  For the perl programmer, treat these objects
as globals accessible from anywhere in your ASP application.

The Apache::ASP object model supports the following:

  Object         Function
  ------         --------
  $Session      - user session state
  $Response     - output to browser
  $Request      - input from browser
  $Application  - application state
  $Server       - general methods

These objects, and their methods are further defined in the 
following sections.

If you would like to define your own global objects for use 
in your scripts and includes, you can initialize them in 
the global.asa Script_OnStart like:

 use vars qw( $Form $Site ); # declare globals
 sub Script_OnStart {
     $Site = My::Site->new;  # init $Site object
     $Form = $Request->Form; # alias form data
     $Server->RegisterCleanup(sub { # garbage collection
				  $Site->DESTROY; 
				  $Site = $Form = undef; 
			      });
 }

In this way you can create site wide application objects
and simple aliases for common functions.

=head2 $Session Object

The $Session object keeps track of user and web client state, in
a persistent manner, making it relatively easy to develop web 
applications.  The $Session state is stored across HTTP connections,
in database files in the Global or StateDir directories, and will 
persist across web server restarts. 

The user session is referenced by a 128 bit / 32 byte MD5 hex hashed cookie, 
and can be considered secure from session id guessing, or session hijacking.
When a hacker fails to guess a session, the system times out for a
second, and with 2**128 (3.4e38) keys to guess, a hacker will not be 
guessing an id any time soon.  

If an incoming cookie matches a timed out or non-existent session,
a new session is created with the incoming id.  If the id matches a
currently active session, the session is tied to it and returned.
This is also similar to the Microsoft ASP implementation.

The $Session reference is a hash ref, and can be used as such to 
store data as in: 

    $Session->{count}++;	# increment count by one
    %{$Session} = ();	# clear $Session data

The $Session object state is implemented through MLDBM,
and a user should be aware of the limitations of MLDBM.  
Basically, you can read complex structures, but not write 
them, directly:

  $data = $Session->{complex}{data};     # Read ok.
  $Session->{complex}{data} = $data;     # Write NOT ok.
  $Session->{complex} = {data => $data}; # Write ok, all at once.

Please see MLDBM for more information on this topic.
$Session can also be used for the following methods and properties:

=over

=item $Session->{CodePage}

Not implemented.  May never be until someone needs it.

=item $Session->{LCID}

Not implemented.  May never be until someone needs it.

=item $Session->{SessionID}

SessionID property, returns the id for the current session,
which is exchanged between the client and the server as a cookie.

=item $Session->{Timeout} [= $minutes]

Timeout property, if minutes is being assigned, sets this 
default timeout for the user session, else returns 
the current session timeout.  

If a user session is inactive for the full
timeout, the session is destroyed by the system.
No one can access the session after it times out, and the system
garbage collects it eventually.

=item $Session->Abandon()

The abandon method times out the session immediately.  All Session
data is cleared in the process, just as when any session times out.

=item $Session->Lock()  

API extension. If you are about to use $Session for many consecutive 
reads or writes, you can improve performance by explicitly locking 
$Session, and then unlocking, like:

  $Session->Lock();
  $Session->{count}++;
  $Session->{count}++;
  $Session->{count}++;
  $Session->UnLock();  

This sequence causes $Session to be locked and unlocked only
1 time, instead of the 6 times that it would be locked otherwise,
2 for each increment with one to read and one to write.

Because of flushing issues with SDBM_File and DB_File databases,
each lock actually ties fresh to the database, so the performance
savings here can be considerable.  

Note that if you have SessionSerialize set, $Session is
already locked for each script invocation automatically, as if
you had called $Session->Lock() in Script_OnStart.  Thus you 
do not need to worry about $Session locking for performance.
Please read the section on SessionSerialize for more info.

=item $Session->UnLock()

API Extension. Unlocks the $Session explicitly.  If you do not call this,
$Session will be unlocked automatically at the end of the 
script.

=back

=head2 $Response Object

This object manages the output from the ASP Application and the 
client web browser.  It does not store state information like the 
$Session object but does have a wide array of methods to call.

=over

=item $Response->{BinaryRef}

API extension. This is a perl reference to the buffered output of 
the $Response object, and can be used in the Script_OnFlush
global.asa event to modify the buffered output at runtime
to apply global changes to scripts output without having to 
modify all the scripts.  These changes take place before 
content is flushed to the client web browser.

 sub Script_OnFlush {
   my $ref = $Response->{BinaryRef};
   $$ref =~ s/\s+/ /sg; # to strip extra white space
 }

Check out the ./site/eg/global.asa for an example of its use.

=item $Response->{Buffer}

Default 1, when TRUE sends output from script to client only at
the end of processing the script.  When 0, response is not buffered,
and client is sent output as output is generated by the script.

=item $Response->{CacheControl}

Default "private", when set to public allows proxy servers to 
cache the content.  This setting controls the value set
in the HTTP header Cache-Control

=item $Response->{Charset}

This member when set appends itself to the value of the Content-Type
HTTP header.  If $Response->{Charset} = 'ISO-LATIN-1' is set, the 
corresponding header would look like:

  Content-Type: text/html; charset=ISO-LATIN-1

=item $Response->{Clean} = 0-9;

API extension. Set the Clean level, default 0, on a per script basis.  
Clean of 1-9 compresses text/html output.  Please see
the Clean config option for more information. This setting may
also be useful even if using compression to obfuscate HTML.

=item $Response->{ContentType} = "text/html"

Sets the MIME type for the current response being sent to the client.
Sent as an HTTP header.

=item $Response->{Debug} = 1|0

API extension.  Default set to value of Debug config.  May be
used to temporarily activate or inactivate $Response->Debug()
behavior.  Something like:

 {
   local $Response->{Debug} = 1;
   $Response->Debug($values);
 }

maybe be used to always log something.  The Debug()
method can be better than AppendToLog() because it will
log data in data structures one level deep, whereas
AppendToLog prints just raw string/scalar values.

=item $Response->{Expires} = $time

Sends a response header to the client indicating the $time 
in SECONDS in which the document should expire.  A time of 0 means
immediate expiration.  The header generated is a standard
HTTP date like: "Wed, 09 Feb 1994 22:23:32 GMT".

=item $Response->{ExpiresAbsolute} = $date

Sends a response header to the client with $date being an absolute
time to expire.  Formats accepted are all those accepted by 
HTTP::Date::str2time(), e.g.

 "Wed, 09 Feb 1994 22:23:32 GMT"     -- HTTP format
 "Tuesday, 08-Feb-94 14:15:29 GMT"   -- old rfc850 HTTP format

 "08-Feb-94"       -- old rfc850 HTTP format    
 "09 Feb 1994"     -- proposed new HTTP format  

 "Feb  3  1994"    -- Unix 'ls -l' format
 "Feb  3 17:03"    -- Unix 'ls -l' format

=item $Response->{FormFill} = 0|1

If true, HTML forms generated by the script output will
be auto filled with data from $Request->Form.  This feature
requires HTML::FillInForm to be installed.  Please see
the FormFill CONFIG for more information.

This setting overrides the FormFill config at runtime
for the script execution only.

=item $Response->{IsClientConnected}

1 if web client is connected, 0 if not.  This value
starts set to 1, and will be updated whenever a
$Response->Flush() is called.  If BufferingOn is
set, by default $Response->Flush() will only be
called at the end of the HTML output.  

As of version 2.23 this value is updated correctly
before global.asa Script_OnStart is called, so 
global script termination may be correctly handled
during that event, which one might want to do 
with excessive user STOP/RELOADS when the web 
server is very busy.

An API extension $Response->IsClientConnected
may be called for refreshed connection status
without calling first a $Response->Flush

=item $Response->{PICS}

If this property has been set, a PICS-Label HTTP header will be
sent with its value.  For those that do not know, PICS is a header
that is useful in rating the internet.  It stands for 
Platform for Internet Content Selection, and you can find more
info about it at: http://www.w3.org

=item $Response->{Status} = $status

Sets the status code returned by the server.  Can be used to
set messages like 500, internal server error

=item $Response->AddHeader($name, $value)

Adds a custom header to a web page.  Headers are sent only before any
text from the main page is sent, so if you want to set a header
after some text on a page, you must turn BufferingOn.

=item $Response->AppendToLog($message)

Adds $message to the server log.  Useful for debugging.

=item $Response->BinaryWrite($data)

Writes binary data to the client.  The only
difference from $Response->Write() is that $Response->Flush()
is called internally first, so the data cannot be parsed 
as an html header.  Flushing flushes the header if has not
already been written.

If you have set the $Response->{ContentType}
to something other than text/html, cgi header parsing (see CGI
notes), will be automatically be turned off, so you will not
necessarily need to use BinaryWrite for writing binary data.

For an example of BinaryWrite, see the binary_write.htm example 
in ./site/eg/binary_write.htm

Please note that if you are on Win32, you will need to 
call binmode on a file handle before reading, if 
its data is binary.

=item $Response->Clear()

Erases buffered ASP output.

=item $Response->Cookies($name, [$key,] $value)

Sets the key or attribute of cookie with name $name to the value $value.
If $key is not defined, the Value of the cookie is set.
ASP CookiePath is assumed to be / in these examples.

 $Response->Cookies('name', 'value'); 
  --> Set-Cookie: name=value; path=/

 $Response->Cookies("Test", "data1", "test value");     
 $Response->Cookies("Test", "data2", "more test");      
 $Response->Cookies(
	"Test", "Expires", 
	&HTTP::Date::time2str(time+86400)
	); 
 $Response->Cookies("Test", "Secure", 1);               
 $Response->Cookies("Test", "Path", "/");
 $Response->Cookies("Test", "Domain", "host.com");
  -->	Set-Cookie:Test=data1=test%20value&data2=more%20test;	\
 		expires=Fri, 23 Apr 1999 07:19:52 GMT;		\
 		path=/; domain=host.com; secure

The latter use of $key in the cookies not only sets cookie attributes
such as Expires, but also treats the cookie as a hash of key value pairs
which can later be accesses by

 $Request->Cookies('Test', 'data1');
 $Request->Cookies('Test', 'data2');

Because this is perl, you can (NOT PORTABLE) reference the cookies
directly through hash notation.  The same 5 commands above could be compressed to:

 $Response->{Cookies}{Test} = 
	{ 
		Secure	=> 1, 
		Value	=>	
			{
				data1 => 'test value', 
				data2 => 'more test'
			},
		Expires	=> 86400, # not portable, see above
		Domain	=> 'host.com',
		Path    => '/'
	};

and the first command would be:

 # you don't need to use hash notation when you are only setting 
 # a simple value
 $Response->{Cookies}{'Test Name'} = 'Test Value'; 

I prefer the hash notation for cookies, as this looks nice, and is 
quite perlish.  It is here to stay.  The Cookie() routine is 
very complex and does its best to allow access to the 
underlying hash structure of the data.  This is the best emulation 
I could write trying to match the Collections functionality of 
cookies in IIS ASP.

For more information on Cookies, please go to the source at
http://home.netscape.com/newsref/std/cookie_spec.html

=item $Response->Debug(@args)

API Extension. If the Debug config option is set greater than 0, 
this routine will write @args out to server error log.  refs in @args 
will be expanded one level deep, so data in simple data structures
like one-level hash refs and array refs will be displayed.  CODE
refs like

 $Response->Debug(sub { "some value" });

will be executed and their output added to the debug output.
This extension allows the user to tie directly into the
debugging capabilities of this module.

While developing an app on a production server, it is often 
useful to have a separate error log for the application
to catch debugging output separately.  One way of implementing 
this is to use the Apache ErrorLog configuration directive to 
create a separate error log for a virtual host. 

If you want further debugging support, like stack traces
in your code, consider doing things like:

 $Response->Debug( sub { Carp::longmess('debug trace') };
 $SIG{__WARN__} = \&Carp::cluck; # then warn() will stack trace

The only way at present to see exactly where in your script
an error occurred is to set the Debug config directive to 2,
and match the error line number to perl script generated
from your ASP script.  

However, as of version 0.10, the perl script generated from the 
asp script should match almost exactly line by line, except in 
cases of inlined includes, which add to the text of the original script, 
pod comments which are entirely yanked out, and <% # comment %> style
comments which have a \n added to them so they still work.

If you would like to see the HTML preceding an error 
while developing, consider setting the BufferingOn 
config directive to 0.

=item $Response->End()

Sends result to client, and immediately exits script.
Automatically called at end of script, if not already called.

=item $Response->ErrorDocument($code, $uri)

API extension that allows for the modification the Apache
ErrorDocument at runtime.  $uri may be a on site document,
off site URL, or string containing the error message.  

This extension is useful if you want to have scripts
set error codes with $Response->{Status} like 401
for authentication failure, and to then control from
the script what the error message looks like.

For more information on the Apache ErrorDocument mechanism,
please see ErrorDocument in the CORE Apache settings,
and the Apache->custom_response() API, for which this method
is a wrapper.

=item $Response->Flush()

Sends buffered output to client and clears buffer.

=item $Response->Include($filename, @args)

This API extension calls the routine compiled from asp script
in $filename with the args @args.  This is a direct translation
of the SSI tag 

  <!--#include file=$filename args=@args-->

Please see the SSI section for more on SSI in general.

This API extension was created to allow greater modularization
of code by allowing includes to be called with runtime 
arguments.  Files included are compiled once, and the 
anonymous code ref from that compilation is cached, thus
including a file in this manner is just like calling a 
perl subroutine.  The @args can be found in @_ in the
includes like:

  # include.inc
  <% my @args = @_; %>

As of 2.23, multiple return values can be returned from
an include like:

 my @rv = $Response->Include($filename, @args);

=item $Response->Include(\%cache_args, @sub_args) *CACHE API*

As of version 2.23, output from an include may be
cached with this API and the CONFIG settings CacheDir & CacheDB.  This
can be used to execute expensive includes only rarely
where applicable, drastically increasing performance in 
some cases.

This API extension applies to the entire include family:

  my @rv = $Response->Include(\%cache_args, @include_args)
  my $html_ref = $Response->TrapInclude(\%cache_args, @include_args)
  $Server->Execute(\%cache_args, @include_args)

For this output cache to work, you must load Apache::ASP
in the Apache parent httpd like so:

  # httpd.conf
  PerlModule Apache::ASP

The cache arguments are shown here

  $Response->Include({
    File => 'file.inc',
    Cache => 1, # to activate cache layer
    Expires => 3600, # to expire in one hour
    LastModified => time() - 600, # to expire if cached before 10 minutes ago
    Key => $Request->Form, # to cache based on checksum of serialized form data,
    Clear => 1, # always executes include & cache output
  }, @include_args);

  File - include file to execute, can be file name or \$script 
    script data passed in as a string reference.

  Cache - activate caching, will run like normal include without this

  Expires - only cache for this long in seconds

  LastModified - if cached before this time(), expire

  Key - The cache item identity.  Can be $data, \$data, \%data, \@data, 
    this data is serialized and combined with the filename & @include_args 
    to create a MD5 checksum to fetch from the cache with. If you wanted
    to cache the results of a search page from form data POSTed, 
    then this key could be 

      { Key => $Request->Form }

  Clear - If set to 1, or boolean true, will always execute the include 
    and update the cache entry for it.

Motivation: If an include takes 1 second to execute
because of complex SQL to a database, and you can
cache the output of this include because it is not realtime data,
and the cache layer runs at .01 seconds, then you have a 
100 fold savings on that part of the script.  Site scalability
can be dramatically increased in this way by intelligently
caching bottlenecks in the web application.

Use Sparingly: If you have a fast include, then it may execute faster
than the cache layer runs, in which case you may actually
slow your site down by using this feature.  Therefore
try to use this sparingly, and only when sure you really
need it.  Apache::ASP scripts generally execute very
quickly, so most developers will not need to use this feature
at all.

=item $Response->Include(\$script_text, @args)

Added in Apache::ASP 2.11, this method allows for executing ASP scripts
that are generated dynamically by passing in a reference to the script
data instead of the file name.  This works just like the normal
$Response->Include() API, except a string reference is passed in
instead of a filename.  For example:

  <%
    my $script = "<\% print 'TEST'; %\>";
    $Response->Include(\$script);
  %>

This include would output TEST.  Note that tokens like
<% and %> must be escaped so Apache::ASP does not try
to compile those code blocks directly when compiling
the original script.  If the $script data were fetched
directly from some external resource like a database,
then these tokens would not need to be escaped at all as in:

  <%
    my $script = $dbh->selectrow_array(
       "select script_text from scripts where script_id = ?",
       undef, $script_id
       );
    $Response->Include(\$script);
  %>

This method could also be used to render other types of dynamic scripts,
like XML docs using XMLSubs for example, though for complex
runtime XML rendering, one should use something better suited like XSLT.
See the $Server->XSLT API for more on this topic.

=item $Response->IsClientConnected()

API Extension.  1 for web client still connected, 0 if 
disconnected which might happen if the user hits the stop button.
The original API for this $Response->{IsClientConnected}
is only updated after a $Response->Flush is called,
so this method may be called for a refreshed status.

Note $Response->Flush calls $Response->IsClientConnected
to update $Response->{IsClientConnected} so to use this
you are going straight to the source!  But if you are doing
a loop like:

  while(@data) {
    $Response->End if ! $Response->{IsClientConnected};
    my $row = shift @data;
    %> <%= $row %> <%
    $Response->Flush;
  }

Then its more efficient to use the member instead of 
the method since $Response->Flush() has already updated
that value for you.

=item $Response->Redirect($url)

Sends the client a command to go to a different url $url.  
Script immediately ends.

=item $Response->TrapInclude($file, @args)

Calls $Response->Include() with same arguments as
passed to it, but instead traps the include output buffer
and returns it as as a perl string reference.  This allows
one to postprocess the output buffer before sending
to the client.

  my $string_ref = $Response->TrapInclude('file.inc');
  $$string_ref =~ s/\s+/ /sg; # squash whitespace like Clean 1
  print $$string_ref;

The data is returned as a referenece to save on what
might be a large string copy.  You may dereference the data
with the $$string_ref notation.

=item $Response->Write($data)

Write output to the HTML page.  <%=$data%> syntax is shorthand for
a $Response->Write($data).  All final output to the client must at
some point go through this method.

=back

=head2 $Request Object

The request object manages the input from the client browser, like
posts, query strings, cookies, etc.  Normal return results are values
if an index is specified, or a collection / perl hash ref if no index 
is specified.  WARNING, the latter property is not supported in 
ActiveState PerlScript, so if you use the hashes returned by such
a technique, it will not be portable.

A normal use of this feature would be to iterate through the 
form variables in the form hash...

 $form = $Request->Form();
 for(keys %{$form}) {
	$Response->Write("$_: $form->{$_}<br>\n");
 }

Please see the ./site/eg/server_variables.htm asp file for this 
method in action.

Note that if a form POST or query string contains duplicate
values for a key, those values will be returned through
normal use of the $Request object:

  @values = $Request->Form('key');

but you can also access the internal storage, which is
an array reference like so:

  $array_ref = $Request->{Form}{'key'};
  @values = @{$array_ref};

Please read the PERLSCRIPT section for more information 
on how things like $Request->QueryString() & $Request->Form()
behave as collections.

=over

=item $Request->{Method}

API extension.  Returns the client HTTP request method, as in
GET or POST.  Added in version 2.31.

=item $Request->{TotalBytes}

The amount of data sent by the client in the body of the 
request, usually the length of the form data.  This is
the same value as $Request->ServerVariables('CONTENT_LENGTH')

=item $Request->BinaryRead([$length])

Returns a string whose contents are the first $length bytes
of the form data, or body, sent by the client request.
If $length is not given, will return all of the form data.
This data is the raw data sent by the client, without any
parsing done on it by Apache::ASP.

Note that BinaryRead will not return any data for file uploads.
Please see the $Request->FileUpload() interface for access
to this data.  $Request->Form() data will also be available
as normal.

=item $Request->ClientCertificate()

Not implemented.

=item $Request->Cookies($name [,$key])

Returns the value of the Cookie with name $name.  If a $key is
specified, then a lookup will be done on the cookie as if it were
a query string.  So, a cookie set by:

 Set-Cookie: test=data1=1&data2=2

would have a value of 2 returned by $Request->Cookies('test','data2').

If no name is specified, a hash will be returned of cookie names 
as keys and cookie values as values.  If the cookie value is a query string, 
it will automatically be parsed, and the value will be a hash reference to 
these values.

When in doubt, try it out.  Remember that unless you set the Expires
attribute of a cookie with $Response->Cookies('cookie', 'Expires', $xyz),
the cookies that you set will only last until you close your browser, 
so you may find your self opening & closing your browser a lot when 
debugging cookies.

For more information on cookies in ASP, please read $Response->Cookies()

=item $Request->FileUpload($form_field, $key)

API extension.  The FileUpload interface to file upload data is
stabilized.  The internal representation of the file uploads
is a hash of hashes, one hash per file upload found in 
the $Request->Form() collection.  This collection of collections
may be queried through the normal interface like so:

  $Request->FileUpload('upload_file', 'ContentType');
  $Request->FileUpload('upload_file', 'FileHandle');
  $Request->FileUpload('upload_file', 'BrowserFile');
  $Request->FileUpload('upload_file', 'Mime-Header');
  $Request->FileUpload('upload_file', 'TempFile');

  * note that TempFile must be use with the UploadTempFile 
    configuration setting.

The above represents the old slow collection interface, 
but like all collections in Apache::ASP, you can reference
the internal hash representation more easily.

  my $fileup = $Request->{FileUpload}{upload_file};
  $fileup->{ContentType};
  $fileup->{BrowserFile};
  $fileup->{FileHandle};
  $fileup->{Mime-Header};
  $fileup->{TempFile};

=item $Request->Form($name)

Returns the value of the input of name $name used in a form
with POST method.  If $name is not specified, returns a ref to 
a hash of all the form data.  One can use this hash to 
create a nice alias to the form data like:

 # in global.asa
 use vars qw( $Form );
 sub Script_OnStart {
   $Form = $Request->Form;
 }
 # then in ASP scripts
 <%= $Form->{var} %>

File upload data will be loaded into $Request->Form('file_field'), 
where the value is the actual file name of the file uploaded, and 
the contents of the file can be found by reading from the file
name as a file handle as in:

 while(read($Request->Form('file_field_name'), $data, 1024)) {};

For more information, please see the CGI / File Upload section,
as file uploads are implemented via the CGI.pm module.  An
example can be found in the installation 
samples ./site/eg/file_upload.asp

=item $Request->Params($name)

API extension. If RequestParams CONFIG is set, the $Request->Params 
object is created with combined contents of $Request->QueryString 
and $Request->Form.  This is for developer convenience simlar 
to CGI.pm's param() method.  Just like for $Response->Form, 
one could create a nice alias like:

 # in global.asa
 use vars qw( $Params );
 sub Script_OnStart {
   $Params = $Request->Params;
 }

=item $Request->QueryString($name)

Returns the value of the input of name $name used in a form
with GET method, or passed by appending a query string to the end of
a url as in http://localhost/?data=value.  
If $name is not specified, returns a ref to a hash of all the query 
string data.

=item $Request->ServerVariables($name)

Returns the value of the server variable / environment variable
with name $name.  If $name is not specified, returns a ref to 
a hash of all the server / environment variables data.  The following
would be a common use of this method:

 $env = $Request->ServerVariables();
 # %{$env} here would be equivalent to the cgi %ENV in perl.

=back

=head2 $Application Object

Like the $Session object, you may use the $Application object to 
store data across the entire life of the application.  Every
page in the ASP application always has access to this object.
So if you wanted to keep track of how many visitors there where
to the application during its lifetime, you might have a line
like this:

 $Application->{num_users}++

The Lock and Unlock methods are used to prevent simultaneous 
access to the $Application object.

=over

=item $Application->Lock()

Locks the Application object for the life of the script, or until
UnLock() unlocks it, whichever comes first.  When $Application
is locked, this guarantees that data being read and written to it 
will not suddenly change on you between the reads and the writes.

This and the $Session object both lock automatically upon
every read and every write to ensure data integrity.  This 
lock is useful for concurrent access control purposes.

Be careful to not be too liberal with this, as you can quickly 
create application bottlenecks with its improper use.

=item $Application->UnLock()

Unlocks the $Application object.  If already unlocked, does nothing.

=item $Application->GetSession($sess_id)

This NON-PORTABLE API extension returns a user $Session given
a session id.  This allows one to easily write a session manager if
session ids are stored in $Application during Session_OnStart, with 
full access to these sessions for administrative purposes.  

Be careful not to expose full session ids over the net, as they
could be used by a hacker to impersonate another user.  So when 
creating a session manager, for example, you could create
some other id to reference the SessionID internally, which 
would allow you to control the sessions.  This kind of application
would best be served under a secure web server.

The ./site/eg/global_asa_demo.asp script makes use of this routine 
to display all the data in current user sessions.

=item $Application->SessionCount()

This NON-PORTABLE method returns the current number of active sessions
in the application, and is enabled by the SessionCount configuration setting.
This method is not implemented as part of the original ASP
object model, but is implemented here because it is useful.  In particular,
when accessing databases with license requirements, one can monitor usage
effectively through accessing this value.

=back

=head2 $Server Object

The server object is that object that handles everything the other
objects do not.  The best part of the server object for Win32 users is 
the CreateObject method which allows developers to create instances of
ActiveX components, like the ADO component.

=over

=item $Server->{ScriptTimeout} = $seconds

Not implemented. May never be.  Please see the 
Apache Timeout configuration option, normally in httpd.conf.  

=item $Server->Config($setting)

API extension.  Allows a developer to read the CONFIG
settings, like Global, GlobalPackage, StateDir, etc.
Currently implemented as a wrapper around 

  Apache->dir_config($setting)

May also be invoked as $Server->Config(), which will
return a hash ref of all the PerlSetVar settings. 

=item $Server->CreateObject($program_id)

Allows use of ActiveX objects on Win32.  This routine returns
a reference to an Win32::OLE object upon success, and nothing upon
failure.  It is through this mechanism that a developer can 
utilize ADO.  The equivalent syntax in VBScript is 

 Set object = Server.CreateObject(program_id)

For further information, try 'perldoc Win32::OLE' from your
favorite command line.

=item $Server->Execute($file, @args)

New method from ASP 3.0, this does the same thing as

  $Response->Include($file, @args)

and internally is just a wrapper for such.  Seems like we
had this important functionality before the IIS/ASP camp!

=item $Server->File()

Returns the absolute file path to current executing script.
Same as Apache->request->filename when running under mod_perl.

ASP API extension.

=item $Server->GetLastError()

Not implemented, will likely not ever be because this is dependent
on how IIS handles errors and is not relevant in Apache.

=item $Server->HTMLEncode( $string || \$string )

Returns an HTML escapes version of $string. &, ", >, <, are each
escapes with their HTML equivalents.  Strings encoded in this nature
should be raw text displayed to an end user, as HTML tags become 
escaped with this method.

As of version 2.23, $Server->HTMLEncode() may take a string reference
for an optmization when encoding a large buffer as an API extension.
Here is how one might use one over the other:

  my $buffer = '&' x 100000;
  $buffer = $Server->HTMLEncode($buffer);
  print $buffer;
    - or -
  my $buffer = '&' x 100000;
  $Server->HTMLEncode(\$buffer);
  print $buffer;

Using the reference passing method in benchmarks on 100K of
data was 5% more efficient, but maybe useful for some.
It saves on copying the 100K buffer twice.

=item $Server->MapInclude($include)

API extension.  Given the include $include, as an absolute or relative file name to the current
executing script, this method returns the file path that the include would
be found from the include search path.  The include search path is the 
current script directory, Global, and IncludesDir directories.

If the include is not found in the includes search path, then undef, or bool false,
is returned. So one may do something like this:

  if($Server->MapInclude('include.inc')) {
    $Response->Include('include.inc');
  }

This code demonstrates how one might only try to execute an include if
it exists, which is useful since a script will error if it tries to execute an include
that does not exist.

=item $Server->MapPath($url);

Given the url $url, absolute, or relative to the current executing script,
this method returns the equivalent filename that the server would 
translate the request to, regardless or whether the request would be valid.

Only a $url that is relative to the host is valid.  Urls like "." and 
"/" are fine arguments to MapPath, but http://localhost would not be.

To see this method call in action, check out the sample ./site/eg/server.htm
script.

=item $Server->Mail(\%mail, %smtp_args);

With the Net::SMTP and Net::Config modules installed, which are part of the 
perl libnet package, you may use this API extension to send email.  The 
\%mail hash reference that you pass in must have values for at least
the To, From, and Subject headers, and the Body of the mail message.

The return value of this routine is 1 for success, 0 for failure.  If the MailHost
SMTP server is not available, this will have a return value of 0.

You could send an email like so:

 $Server->Mail({
		To => 'somebody@yourdomain.com.foobar',
		From => 'youremail@yourdomain.com.foobar',
		Subject => 'Subject of Email',
		Body => 
		 'Body of message. '.
		 'You might have a lot to say here!',
		Organization => 'Your Organization',
                CC => 'youremailcc@yourdomain.com.foobar',
                BCC => 'youremailbcc@yourdomain.com.foobar',
		Debug => 0 || 1,
	       });

Any extra fields specified for the email will be interpreted
as headers for the email, so to send an HTML email, you 
could set 'Content-Type' => 'text/html' in the above example.

If you have MailFrom configured, this will be the default
for the From header in your email.  For more configuration
options like the MailHost setting, check out the CONFIG section.

The return value of this method call will be boolean for
success of the mail being sent.

If you would like to specially configure the Net::SMTP 
object used internally, you may set %smtp_args and they
will be passed on when that object is initialized.
"perldoc Net::SMTP" for more into on this topic.

If you would like to include the output of an ASP page as the
body of the mail message, you might do something like:

  my $mail_body = $Response->TrapInclude('mail_body.inc');
  $Server->Mail({ %mail, Body => $$mail_body });

=item $Server->RegisterCleanup($sub) 

 non-portable extension

Sets a subroutine reference to be executed after the script ends,
whether normally or abnormally, the latter occurring 
possibly by the user hitting the STOP button, or the web server
being killed.  This subroutine must be a code reference 
created like:

 $Server->RegisterCleanup(sub { $main::Session->{served}++; });
   or
 sub served { $main::Session->{served}++; }
 $Server->RegisterCleanup(\&served);

The reference to the subroutine passed in will be executed.
Though the subroutine will be executed in anonymous context, 
instead of the script, all objects will still be defined 
in main::*, that you would reference normally in your script.  
Output written to $main::Response will have no affect at 
this stage, as the request to the www client has already completed.

Check out the ./site/eg/register_cleanup.asp script for an example
of this routine in action.

=item $Server->Transfer($file, @args)

New method from ASP 3.0.  Transfers control to another script.  
The Response buffer will not be cleared automatically, so if you 
want this to serve as a faster $Response->Redirect(), you will need to 
call $Response->Clear() before calling this method.  

This new script will take over current execution and 
the current script will not continue to be executed
afterwards.  It differs from Execute() because the 
original script will not pick up where it left off.

As of Apache::ASP 2.31, this method now accepts optional
arguments like $Response->Include & $Server->Execute.  
$Server->Transfer is now just a wrapper for:

  $Response->Include($file, @args);
  $Response->End;

=item $Server->URLEncode($string)

Returns the URL-escaped version of the string $string. +'s are substituted in
for spaces and special characters are escaped to the ascii equivalents.
Strings encoded in this manner are safe to put in urls... they are especially
useful for encoding data used in a query string as in:

 $data = $Server->URLEncode("test data");
 $url = "http://localhost?data=$data";

 $url evaluates to http://localhost?data=test+data, and is a 
 valid URL for use in anchor <a> tags and redirects, etc.

=item $Server->URL($url, \%params) 

Will return a URL with %params serialized into a query 
string like:

  $url = $Server->URL('test.asp', { test => value });

which would give you a URL of test.asp?test=value

Used in conjunction with the SessionQuery* settings, the returned
URL will also have the session id inserted into the query string, 
making this a critical part of that method of implementing 
cookieless sessions.  For more information on that topic 
please read on the setting
in the CONFIG section, and the SESSIONS section too.

=item $Server->XSLT(\$xsl_data, \$xml_data)

 * NON-PORTABLE API EXTENSION *

This method takes string references for XSL and XML data
and returns the XSLT output as a string reference like:

  my $xslt_data_ref = $Server->XSLT(\$xsl_data, \$xml_data)
  print $$xslt_data_ref;

The XSLT parser defaults to XML::XSLT, and is configured with the 
XSLTParser setting, which can also use XML::Sablotron ( support added in 2.11 ), 
and XML::LibXSLT ( support added in 2.29 ). 
Please see the CONFIG section for more information on the 
XSLT* settings that drive this API.  The XSLT setting itself 
uses this API internally to do its rendering.

This API was created to allow developers easy XSLT component
rendering without having to render the entire ASP scripts
via XSLT.  This will make an easy plugin architecture for
those looking to integrate XML into their existing ASP
application frameworks.

At some point, the API will likely take files as arguments,
but not as of the 2.11 release.

=back

=head1 SSI

SSI is great!  One of the main features of server side includes 
is to include other files in the script being requested.  In Apache::ASP, 
this is implemented in a couple ways, the most crucial of which
is implemented in the file include.  Formatted as

 <!--#include file=filename.inc-->

,the .inc being merely a convention, text from the included 
file will be inserted directly into the script being executed
and the script will be compiled as a whole.  Whenever the 
script or any of its includes change, the script will be 
recompiled.

Includes go a great length to promote good decomposition
and code sharing in ASP scripts, but they are still 
fairly static.  As of version .09, includes may have dynamic
runtime execution, as subroutines compiled into the global.asa
namespace.  The first way to invoke includes dynamically is

 <!--#include file=filename.inc args=@args-->

If @args is specified, Apache::ASP knows to execute the 
include at runtime instead of inlining it directly into 
the compiled code of the script.  It does this by
compiling the script at runtime as a subroutine, and 
caching it for future invocations.  Then the compiled
subroutine is executed and has @args passed into its
as arguments.

This is still might be too static for some, as @args
is still hardcoded into the ASP script, so finally,
one may execute an include at runtime by utilizing
this API extension

   $Response->Include("filename.inc", @args);

which is a direct translation of the dynamic include above.

Although inline includes should be a little faster,
runtime dynamic includes represent great potential
savings in httpd memory, as includes are shared
between scripts keeping the size of each script
to a minimum.  This can often be significant saving
if much of the formatting occurs in an included 
header of a www page.

By default, all includes will be inlined unless
called with an args parameter.  However, if you
want all your includes to be compiled as subs and 
dynamically executed at runtime, turn the DynamicIncludes
config option on as documented above.

That is not all!  SSI is full featured.  One of the 
things missing above is the 

 <!--#include virtual=filename.cgi-->

tag.  This and many other SSI code extensions are available
by filtering Apache::ASP output through Apache::SSI via
the Apache::Filter and the Filter config options.  For
more information on how to wire Apache::ASP and Apache::SSI
together, please see the Filter config option documented
above.  Also please see Apache::SSI for further information
on the capabilities it offers.

=head1 EXAMPLES

Use with Apache.  Copy the ./site/eg directory from the ASP installation 
to your Apache document tree and try it out!  You have to put 
"AllowOverride All" in your <Directory> config section to let the 
.htaccess file in the ./site/eg installation directory do its work.  

IMPORTANT (FAQ): Make sure that the web server has write access to 
that directory.  Usually a 

 chmod -R 0777 eg

will do the trick :)

=head1 SESSIONS

Cookies are used by default for user $Session support ( see OBJECTS ).  
In order to track a web user and associate server side data 
with that client, the web server sets, and the web client returns 
a 32 byte session id identifier cookie.  This implementation 
is very secure and  may be used in secure HTTPS transactions, 
and made stronger with SecureSession and ParanoidSession 
settings (see CONFIG ).

However good cookies are for this kind of persistent
state management between HTTP requests, they have long 
been under fire for security risks associated with
JavaScript security exploits and privacy abuse by 
large data tracking companies. 

Because of these reasons, web users will sometimes turn off
their cookies, rendering normal ASP session implementations
powerless, resulting in a new $Session generated every request.
This is not good for ASP style sessions.

=head2 Cookieless Sessions

 *** See WARNING Below ***

So we now have more ways to track sessions with the 
SessionQuery* CONFIG settings, that allow a web developer 
to embed the session id in URL query strings when use 
of cookies is denied.  The implementations work such that
if a user has cookies turned on, then cookies will be 
used, but for those users with cookies turned off,
the session ids will be parsed into document URLs.

The first and easiest method that a web developer may use 
to implement cookieless sessions are with SessionQueryParse*
directives which enable Apache::ASP to the parse the session id
into document URLs on the fly.  Because this is resource
inefficient, there is also the SessionQuery* directives
that may be used with the $Server->URL($url,\%params) method to 
generate custom URLs with the session id in its query string.

To see an example of these cookieless sessions in action, 
check out the ./site/eg/session_query_parse.asp example.

 *** WARNING ***

If you do use these methods, then be VERY CAREFUL
of linking offsite from a page that was accessed with a 
session id in a query string.  This is because this session
id will show up in the HTTP_REFERER logs of the linked to 
site, and a malicious hacker could use this information to
compromise the security of your site's $Sessions, even if 
these are run under a secure web server.  

In order to shake a session id off an HTTP_REFERER for a link 
taking a user offsite, you must point that link to a redirect 
page that will redirect a user, like so:

 <% 
    # "cross site scripting bug" prevention
    my $sanitized_url = 
	$Server->HTMLEncode($Response->QueryString('OffSiteUrl'));
 %>
 <html>
 <head>
 <meta http-equiv=refresh content='0;URL=<%=$sanitized_url%>'>
 </head>
 <body>	
	Redirecting you offsite to 
	<a href=<%=$sanitized_url%> >here</a>...
 </body>
 </html>

Because the web browser visits a real page before being redirected
with the <meta> tag, the HTTP_REFERER will be set to this page.
Just be sure to not link to this page with a session id in its
query string.  

Unfortunately a simple $Response->Redirect() will not work here,
because the web browser will keep the HTTP_REFERER of the 
original web page if only a normal redirect is used.

=head1 XML/XSLT

=head2 Custom Tags with XMLSubsMatch

Before XML, there was the need to make HTML markup smarter.
Apache::ASP gives you the ability to have a perl
subroutine handle the execution of any predefined tag,
taking the tag descriptors, and the text contained between,
as arguments of the subroutine.  This custom tag
technology can be used to extend a web developer's abilities
to add dynamic pieces without having to visibly use 
<% %> style code entries.

So, lets say that you have a table that 
you want to insert for an employee with contact 
info and the like, you could set up a tag like:

 <my:new-employee name="Jane" last="Doe" phone="555-2222">
   Jane Doe has been here since 1998.
 </my:new-employee>

To render it with a custom tag, you would tell 
the Apache::ASP parser to render the tag with a 
subroutine:

  PerlSetVar XMLSubsMatch my:new-employee

Any colons, ':', in the XML custom tag will turn
into '::', a perl package separator, so the my:employee
tag would translate to the my::employee subroutine, or the 
employee subroutine in the my package.  Any dash "-" will 
also be translated to an underscore "_", as dash is not valid
in the names of perl subroutines.

Then you would create the my::employee subroutine in the my 
perl package or whereever like so:

  package my;
  sub new_employee {
    my($attributes, $body) = @_;
    $main::Response->Include('new_employee.inc', $attributes, $body);
  }
  1;

  <!-- # new_employee.inc file somewhere else, maybe in Global directory -->
  <% my($attributes, $body) = @_; %>
  <table>
  <% for('name', 'last', 'phone') { %>
    <tr>
      <td><b><%=ucfirst $_ %></b>:</td>
      <td><%= $attributes->{$_} %></td>
    </tr>
  <% } %>
  <tr><td colspan=2><%= $body %></td></tr>
  </table>
  <!-- # end new_employee.inc file -->

The $main::Response->Include() would then delegate the rendering
of the new-employee to the new_employee.inc ASP script include.

Though XML purists would not like this custom tag technology
to be related to XML, the reality is that a careful
site engineer could render full XML documents with this
technology, applying all the correct styles that one might
otherwise do with XSLT. 

Custom tags defined in this way can be used as XML tags
are defined with both a body and without as it

  <my:new-employee>...</my:new-employee>

and just

  <my:new-employee />

These tags are very powerful in that they can also
enclose normal ASP logic, like:

  <my:new-employee>
    <!-- normal ASP logic -->
    <% my $birthday = &HTTP::Date::time2str(time - 25 * 86400 * 365); %>

    <!-- ASP inserts -->
    This employee has been online for <%= int(rand()*600)+1 %>
    seconds, and was born near <%= $birthday %>.
  </my:new-employee>   

For an example of this custom XML tagging in action, please check 
out the ./site/eg/xml_subs.asp script.  

=head2 XSLT Tranformations

XML is good stuff, but what can you use it for? The principle is
that by having data and style separated in XML and XSL files, you
can reformat your data more easily in the future, and you 
can render your data in multiple formats, just as easily 
as for your web site, so you might render your site to
a PDA, or a cell phone just as easily as to a browser, and all
you have to do is set up the right XSL stylesheets to do the
transformation (XSLT).

With native XML/XSLT support, Apache::ASP scripts may be the
source of XML data that the XSL file transforms, and the XSL file
itself will be first executed as an ASP script also.  The XSLT 
transformation is handled by XML::XSLT or XML::Sablotron and you can
see an example of it in action at the ./site/eg/xslt.xml XML script.  

To specify a XSL stylesheet, use the setting:

  PerlSetVar XSLT template.xsl

where template.xsl could be any file.  By default this will
XSLT transform all ASP scripts so configured, but you can separate xml
scripts from the rest with the setting:

  PerlSetVar XSLTMatch xml$

where all files with the ending xml would undergo a XSLT transformation.

Note that XSLT depends on the installation of XML::XSLT,
which in turn depends on XML::DOM, and XML::Parser.
As of version 2.11, XML::Sablotron may also be used by
setting:

  PerlSetVar XSLTParser XML::Sablotron

and XML::LibXSLT may be used, as of 2.29, by setting

  PerlSetVar XSLTParser XML::LibXSLT

If you would like to install XML::Sablotron or XML::LibXSLT,
you will first have to install the libraries that these perl
modules use, which you can get at:

  libxslt - The XSLT C Library for Gnome
  http://xmlsoft.org/XSLT/

  Sablotron - Ginger Alliance
  http://www.gingerall.com

For more on XML::XSLT, the default XSLT engine that Apache::ASP
will use, please see:

  XML::XSLT
  http://xmlxslt.sourceforge.net/

XML:XSLT was the first supported XSLT engine as has the benefit
of being written in pure perl so that though while it is slower
than the other solutions, it is easier to port.

If you would like to cache XSLT tranformations, which
is highly recommended, just set:

  PerlSetVar XSLTCache 1

Please see the Cache settings in the CONFIG section for
more about how to configure the XSLTCache.

=head2 References

For more information about XSLT, please see the standard at:

  http://www.w3.org/TR/xslt

For their huge ground breaking XML efforts, these other XML OSS
projects need mention:

  Cocoon - XML-based web publishing, in Java 
  http://cocoon.apache.org/

  AxKit - XML web publishing with Apache & mod_perl
  http://www.axkit.org/

=head1 CGI

CGI has been the standard way of deploying web applications long before
ASP came along.  In the CGI gateway world, CGI.pm has been a widely
used module in building CGI applications, and Apache::ASP is compatible
with scripts written with CGI.pm.  Also, as of version 2.19, Apache::ASP
can run in standalone CGI mode for the Apache web server without
mod_perl being available.  See "Standalone CGI Mode" section below.

Following are some special notes with respect to compatibility with CGI
and CGI.pm.  Use of CGI.pm in any of these ways was made possible through 
a great amount of work, and is not guaranteed to be portable with other perl 
ASP implementations, as other ASP implementations will likely be more limited.

=over

=item Standalone CGI Mode, without mod_perl

As of version 2.19, Apache::ASP scripts may be run as standalone
CGI scripts without mod_perl being loaded into Apache.  Work
to date has only been done with mod_cgi scripts under Apache on a
Unix platform, and it is unlikely to work under other web servers 
or Win32 operating systems without further development.

To run the ./site/eg scripts as CGI scripts, you copy the 
./site directory to some location accessible by your web
server, in this example its /usr/local/apache/htdocs/aspcgi, 
then in your httpd.conf activate Apache::ASP cgi
scripts like so:

 Alias /aspcgi/ /usr/local/apache/htdocs/aspcgi/
 <Directory /usr/local/apache/htdocs/aspcgi/eg/ >
   AddType application/x-httpd-cgi .htm
   AddType application/x-httpd-cgi .html
   AddType application/x-httpd-cgi .asp
   AddType application/x-httpd-cgi .xml
   AddType application/x-httpd-cgi .ssi
   AllowOverride None
   Options +ExecCGI +Indexes
 </Directory>

Then install the asp-perl script from the distribution 
into /usr/bin, or some other directory.  This is 
so the CGI execution line at the top of those scripts
will invoke the asp-perl wrapper like so:

 #!/usr/bin/perl /usr/bin/asp-perl

The asp-perl script is a cgi wrapper that sets up the 
Apache::ASP environment in lieu of the normal mod_perl
handler request.  Because there is no Apache->dir_config()
data available under mod_cgi, the asp-perl script will load
a asp.conf file that may define a hash %Config of
data for populating the dir_config() data.  An example
of a complex asp.conf file is at ./site/eg/asp.conf

So, a trivial asp.conf file might look like:

 # asp.conf
 %Config = (
   'Global' => '.',
   'StateDir' => '/tmp/aspstate',
   'NoState' => 0,
   'Debug' => 3,
 );

The default for NoState is 1 in CGI mode, so one must
set NoState to 0 for objects like $Session & $Application
to be defined.

=item CGI.pm

CGI.pm is a very useful module that aids developers in 
the building of these applications, and Apache::ASP has been made to 
be compatible with function calls in CGI.pm.  Please see cgi.htm in the 
./site/eg directory for a sample ASP script written almost entirely in CGI.

As of version 0.09, use of CGI.pm for both input and output is seamless
when working under Apache::ASP.  Thus if you would like to port existing
cgi scripts over to Apache::ASP, all you need to do is wrap <% %> around
the script to get going.  This functionality has been implemented so that
developers may have the best of both worlds when building their 
web applications.

For more information about CGI.pm, please see the web site

  http://stein.cshl.org/WWW/software/CGI/

=item Query Object Initialization

You may create a CGI.pm $query object like so:

	use CGI;
	my $query = new CGI;

As of Apache::ASP version 0.09, form input may be read in 
by CGI.pm upon initialization.  Before, Apache::ASP would 
consume the form input when reading into $Request->Form(), 
but now form input is cached, and may be used by CGI.pm input
routines.

=item CGI headers

Not only can you use the CGI.pm $query->header() method
to put out headers, but with the CgiHeaders config option
set to true, you can also print "Header: value\n", and add 
similar lines to the top of your script, like:

 Some-Header: Value
 Some-Other: OtherValue

 <html><body> Script body starts here.

Once there are no longer any cgi style headers, or the 
there is a newline, the body of the script begins. So
if you just had an asp script like:

    print join(":", %{$Request->QueryString});

You would likely end up with no output, as that line is
interpreted as a header because of the semicolon.  When doing
basic debugging, as long as you start the page with <html>
you will avoid this problem.

=item print()ing CGI

CGI is notorious for its print() statements, and the functions in CGI.pm 
usually return strings to print().  You can do this under Apache::ASP,
since print just aliases to $Response->Write().  Note that $| has no
affect.

	print $query->header();
	print $query->start_form();

=item File Upload

CGI.pm is used for implementing reading the input from file upload.  You
may create the file upload form however you wish, and then the 
data may be recovered from the file upload by using $Request->Form().
Data from a file upload gets written to a file handle, that may in
turn be read from.  The original file name that was uploaded is the 
name of the file handle.

	my $filehandle = $Request->Form('file_upload_field_name');
	print $filehandle; # will get you the file name
	my $data;
	while(read($filehandle, $data, 1024)) {
		# data from the uploaded file read into $data
	};

Please see the docs on CGI.pm (try perldoc CGI) for more information
on this topic, and ./site/eg/file_upload.asp for an example of its use.
Also, for more details about CGI.pm itself, please see the web site:

    http://stein.cshl.org/WWW/software/CGI/

Occasionally, a newer version of CGI.pm will be released which breaks
file upload compatibility with Apache::ASP.  If you find this to occur,
then you might consider downgrading to a version that works.  For example,
one can install a working CGI.pm v2.78 for a working version, and to 
get old versions of this module, one can go to BACKPAN at:

    http://backpan.cpan.org/modules/by-authors/id/L/LD/LDS/

There is also $Request->FileUpload() API extension that you can use to get 
more data about a file upload, so that the following properties are
available for querying:

  my $file_upload = $Request->{FileUpload}{upload_field};
  $file_upload->{BrowserFile}
  $file_upload->{FileHandle}
  $file_upload->{ContentType}

  # only if FileUploadTemp is set
  $file_upload->{TempFile}	

  # whatever mime headers are sent with the file upload
  # just "keys %$file_upload" to find out
  $file_upload->{?Mime-Header?}

Please see the $Request section in OBJECTS for more information.

=back

=head1 PERLSCRIPT

Much work has been done to bring compatibility with ASP applications
written in PerlScript under IIS.  Most of that work revolved around
bringing a Win32::OLE Collection interface to many of the objects
in Apache::ASP, which are natively written as perl hashes.

New as of version 2.05 is new functionality enabled with the 
CollectionItem setting, to giver better support to more recent PerlScript syntax.
This seems helpful when porting from an IIS/PerlScript code base.
Please see the CONFIG section for more info.

The following objects in Apache::ASP respond as Collections:

        $Application
	$Session
	$Request->FileUpload *
	$Request->FileUpload('upload_file') *
	$Request->Form
	$Request->QueryString
	$Request->Cookies
	$Response->Cookies
	$Response->Cookies('some_cookie')	

  * FileUpload API Extensions

And as such may be used with the following syntax, as compared
with the Apache::ASP native calls.  Please note the native Apache::ASP
interface is compatible with the deprecated PerlScript interface.

 C = PerlScript Compatibility	N = Native Apache::ASP 
  
 ## Collection->Contents($name) 
 [C] $Application->Contents('XYZ')		
 [N] $Application->{XYZ}

 ## Collection->SetProperty($property, $name, $value)
 [C] $Application->Contents->SetProperty('Item', 'XYZ', "Fred");
 [N] $Application->{XYZ} = "Fred"
	
 ## Collection->GetProperty($property, $name)
 [C] $Application->Contents->GetProperty('Item', 'XYZ')		
 [N] $Application->{XYZ}

 ## Collection->Item($name)
 [C] print $Request->QueryString->Item('message'), "<br>\n\n";
 [N] print $Request->{QueryString}{'message'}, "<br>\n\n";		

 ## Working with Cookies
 [C] $Response->SetProperty('Cookies', 'Testing', 'Extra');
 [C] $Response->SetProperty('Cookies', 'Testing', {'Path' => '/'});
 [C] print $Request->Cookies(Testing) . "<br>\n";
 [N] $Response->{Cookies}{Testing} = {Value => Extra, Path => '/'};
 [N] print $Request->{Cookies}{Testing} . "<br>\n";

Several incompatibilities exist between PerlScript and Apache::ASP:

 > Collection->{Count} property has not been implemented.
 > VBScript dates may not be used for Expires property of cookies.
 > Win32::OLE::in may not be used.  Use keys() to iterate over.
 > The ->{Item} property does not work, use the ->Item() method.

=head1 STYLE GUIDE

Here are some general style guidelines.  Treat these as tips for
best practices on Apache::ASP development if you will.

=head2 UseStrict

One of perl's blessings is also its bane, variables do not need to be
declared, and are by default globally scoped.  The problem with this in 
mod_perl is that global variables persist from one request to another
even if a different web browser is viewing a page.  

To avoid this problem, perl programmers have often been advised to
add to the top of their perl scripts:

  use strict;

In Apache::ASP, you can do this better by setting:

  PerlSetVar UseStrict 1

which will cover both script & global.asa compilation and will catch 
"use strict" errors correctly.  For perl modules, please continue to
add "use strict" to the top of them.

Because its so essential in catching hard to find errors, this 
configuration will likely become the default in some future release.
For now, keep setting it.

=head2 Do not define subroutines in scripts.

DO NOT add subroutine declarations in scripts.  Apache::ASP is optimized
by compiling a script into a subroutine for faster future invocation.
Adding a subroutine definition to a script then looks like this to 
the compiler:

  sub page_script_sub {
    ...
    ... some HTML ...
    ...
    sub your_sub {
      ...
    }
    ...
  }

The biggest problem with subroutines defined in subroutines is the 
side effect of creating closures, which will not behave as usually
desired in a mod_perl environment.  To understand more about closures,
please read up on them & "Nested Subroutines" at:

  http://perl.apache.org/docs/general/perl_reference/perl_reference.html

Instead of defining subroutines in scripts, you may add them to your sites
global.asa, or you may create a perl package or module to share
with your scripts.  For more on perl objects & modules, please see:

  http://www.perldoc.com/perl5.8.0/pod/perlobj.html

=head2 Use global.asa's Script_On* Events

Chances are that you will find yourself doing the same thing repeatedly
in each of your web application's scripts.  You can use Script_OnStart
and Script_OnEnd to automate these routine tasks.  These events are
called before and after each script request.

For example, let's say you have a header & footer you would like to 
include in the output of every page, then you might:

 # global.asa
 sub Script_OnStart {
   $Response->Include('header.inc');
 }
 sub Script_OnEnd {
   $Response->Include('footer.inc');
 }

Or let's say you want to initialize a global database connection
for use in your scripts:

 # global.asa
 use Apache::DBI;   # automatic persistent database connections
 use DBI;

 use vars qw($dbh); # declare global $dbh

 sub Script_OnStart {
   # initialize $dbh
   $dbh = DBI->connect(...);

   # force you to explicitly commit when you want to save data
   $Server->RegisterCleanup(sub { $dbh->rollback; });
 }

 sub Script_OnEnd {
   # not really necessary when using persistent connections, but
   # will free this one object reference at least
   $dbh = undef;
 }

=head1 FAQ

The following are some frequently asked questions
about Apache::ASP.

=head2 Installation

=item Examples don't work, I see the ASP script in the browser?

This is most likely that Apache is not configured to execute
the Apache::ASP scripts properly.  Check the INSTALL QuickStart
section for more info on how to quickly set up Apache to 
execute your ASP scripts.

=item Apache Expat vs. XML perl parsing causing segfaults, what do I do?

Make sure to compile apache with expat disabled.  The
./make_httpd/build_httpds.sh in the distribution will do 
this for you, with the --disable-rule=EXPAT in particular:

 cd ../$APACHE
 echo "Building apache =============================="
 ./configure \
    --prefix=/usr/local/apache \
    --activate-module=src/modules/perl/libperl.a \
    --enable-module=ssl \
    --enable-module=proxy \
    --enable-module=so \
    --disable-rule=EXPAT

                   ^^^^^

keywords: segmentation fault, segfault seg fault

=item Why do variables retain their values between requests?

Unless scoped by my() or local(), perl variables in mod_perl
are treated as globals, and values set may persist from one 
request to another. This can be seen in as simple a script
as this:

  <HTML><BODY>
    $counter++;
    $Response->Write("<BR>Counter: $counter");
  </BODY></HTML>

The value for $counter++ will remain between requests.
Generally use of globals in this way is a BAD IDEA,
and you can spare yourself many headaches if do 
"use strict" perl programming which forces you to 
explicity declare globals like:

  use vars qw($counter);

You can make all your Apache::ASP scripts strict by
default by setting:

  PerlSetVar UseStrict 1

=item Apache errors on the PerlHandler or PerlModule directives ?

You get an error message like this:

 Invalid command 'PerlModule', perhaps mis-spelled or defined by a 
 module not included in the server configuration.

You do not have mod_perl correctly installed for Apache.  The PerlHandler
and PerlModule directives in Apache *.conf files are extensions enabled by mod_perl
and will not work if mod_perl is not correctly installed.

Common user errors are not doing a 'make install' for mod_perl, which 
installs the perl side of mod_perl, and not starting the right httpd
after building it.  The latter often occurs when you have an old apache
server without mod_perl, and you have built a new one without copying
over to its proper location.

To get mod_perl, go to http://perl.apache.org

=item Error: no request object (Apache=SCALAR(0x???????):)

Your Apache + mod_perl build is not working properly, 
and is likely a RedHat Linux RPM DSO build.  Make sure
you statically build your Apache + mod_perl httpd,
recompiled fresh from the sources.

=item I am getting a tie or MLDBM / state error message, what do I do?

Make sure the web server or you have write access to the eg directory,
or to the directory specified as Global in the config you are using.
Default for Global is the directory the script is in (e.g. '.'), but should
be set to some directory not under the www server document root,
for security reasons, on a production site.

Usually a 

 chmod -R -0777 eg

will take care of the write access issue for initial testing purposes.

Failing write access being the problem, try upgrading your version
of Data::Dumper and MLDBM, which are the modules used to write the 
state files.

=head2 Sessions

=item How can I use $Session to store complex data structures.

Very carefully.  Please read the $Session documentation in 
the OBJECTS section.  You can store very complex objects
in $Session, but you have to understand the limits, and 
the syntax that must be used to make this happen.

In particular, stay away from statements that that have 
more than one level of indirection on the left side of
an assignment like:

  $Session->{complex}{object} = $data;

=item How can I keep search engine spiders from killing the session manager?

If you want to disallow session creation for certain non web 
browser user agents, like search engine spiders, you can use a mod_perl
PerlInitHandler like this to set configuration variables at runtime:

 # put the following code into httpd.conf and stop/start apache server
 PerlInitHandler My::InitHandler

 <Perl>

  package My::InitHandler;
  use Apache;

  sub handler {
    my $r = shift; # get the Apache request object

    # if not a Mozilla User Agent, then disable sessions explicitly
    unless($r->headers_in('User-Agent') =~ /^Mozilla/) {
       $r->dir_config('AllowSessionState', 'Off');
    }

    return 200; # return OK mod_perl status code
  }

  1;

 </Perl>

This will configure your environment before Apache::ASP executes
and sees the configuration settings.  You can use the mod_perl
API in this way to configure Apache::ASP at runtime.

Note that the Session Manager is very robust on its own, and denial
of service attacks of the types that spiders and other web bots 
normally execute are not likely to affect the Session Manager significantly.

=item How can I use $Session to store a $dbh database handle ?

You cannot use $Session to store a $dbh handle.  This can 
be awkward for those coming from the IIS/NT world, where
you could store just about anything in $Session, but this
boils down to a difference between threads vs. processes.

Database handles often have per process file handles open,
which cannot be shared between requests, so though you 
have stored the $dbh data in $Session, all the other 
initializations are not relevant in another httpd process.

All is not lost! Apache::DBI can be used to cache 
database connections on a per process basis, and will
work for most cases.

=head2 Development

=item VBScript or JScript supported?

Yes, but not with this Perl module.  For ASP with other scripting
languages besides Perl, you will need to go with a commercial vendor
in the UNIX world.  Sun has such a solution.
Of course on Windows NT and Windows 2000, you get VBScript for free with IIS.

  Sun ONE Active Server Pages (formerly Sun Chili!Soft ASP)
  http://www.chilisoft.com

=item How is database connectivity handled?

Database connectivity is handled through perl's DBI & DBD interfaces.
In the UNIX world, it seems most databases have cross platform support in perl.
You can find the book on DBI programming at http://www.oreilly.com/catalog/perldbi/

DBD::ODBC is often your ticket on Win32.  On UNIX, commercial vendors
like OpenLink Software (http://www.openlinksw.com/) provide the nuts and 
bolts for ODBC.

Database connections can be cached per process with Apache::DBI.

=item What is the best way to debug an ASP application ?

There are lots of perl-ish tricks to make your life developing
and debugging an ASP application easier.  For starters,
you will find some helpful hints by reading the 
$Response->Debug() API extension, and the Debug
configuration directive.

=item How are file uploads handled?

Please see the CGI section.  File uploads are implemented
through CGI.pm which is loaded at runtime only for this purpose.
This is the only time that CGI.pm will be loaded by Apache::ASP,
which implements all other cgi-ish functionality natively.  The
rationale for not implementing file uploads natively is that 
the extra 100K in memory for CGI.pm shouldn't be a big deal if you 
are working with bulky file uploads.

=item How do I access the ASP Objects in general?

All the ASP objects can be referenced through the main package with
the following notation:

 $main::Response->Write("html output");

This notation can be used from anywhere in perl, including routines
registered with $Server->RegisterCleanup().  

You use the normal notation in your scripts, includes, and global.asa:

 $Response->Write("html output");

=item Can I print() in ASP?

Yes.  You can print() from anywhere in an ASP script as it aliases
to the $Response->Write() method.  Using print() is portable with
PerlScript when using Win32::ASP in that environment.

=item Do I have access to ActiveX objects?

Only under Win32 will developers have access to ActiveX objects through
the perl Win32::OLE interface.  This will remain true until there
are free COM ports to the UNIX world.  At this time, there is no ActiveX
for the UNIX world.

=head2 Support and Production

=item How do I get things I want done?!

If you find a problem with the module, or would like a feature added,
please mail support, as listed in the SUPPORT section, and your 
needs will be promptly and seriously considered, then implemented.

=item What is the state of Apache::ASP?  Can I publish a web site on it?

Apache::ASP has been production ready since v.02.  Work being done
on the module is on a per need basis, with the goal being to eventually
have the ASP API completed, with full portability to ActiveState PerlScript
and MKS PScript.  If you can suggest any changes to facilitate these
goals, your comments are welcome.

=head1 TUNING

A little tuning can go a long way, and can make the difference between
a web site that gets by, and a site that screams with speed.  With
Apache::ASP, you can easily take a poorly tuned site running at
10 hits/second to 50+ hits/second just with the right configuration.

Documented below are some simple things you can do to make the 
most of your site.

=head2 Online Resources

For more tips & tricks on tuning Apache and mod_perl, please see the tuning
documents at:

  Stas Bekman's mod_perl guide
  http://perl.apache.org/guide/

Written in late 1999 this article provides an early look at 
how to tune your Apache::ASP web site.  It has since been
updated to remain current with Apache::ASP v2.29+

  Apache::ASP Site Tuning
  http://www.chamas.com/asp/articles/perlmonth3_tune.html

=head2 Tuning & Benchmarking

When performance tuning, it is important to have a tool to
measure the impact of your tuning change by change.
The program ab, or Apache Bench, provides this functionality
well, and is freely included in the apache distribution.

Because performance tuning can be a neverending affair,
it is a good idea to establish a threshold where performance
is "good enough", that once reached, tuning stops.

=head2 $Application & $Session State

Use NoState 1 setting if you don't need the $Application or $Session
objects. State objects such as these tie to files on disk and will incur a
performance penalty.

If you need the state objects $Application and $Session, and if 
running an OS that caches files in memory, set your "StateDir" 
directory to a cached file system.  On WinNT, all files 
may be cached, and you have no control of this.  On Solaris, /tmp is
a RAM disk and would be a good place to set the "StateDir" config 
setting to.  When cached file systems are used there is little 
performance penalty for using state files.  Linux tends to do a good job 
caching its file systems, so pick a StateDir for ease of system 
administration.

On Win32 systems, where mod_perl requests are serialized, you 
can freely use SessionSerialize to make your $Session requests
faster, and you can achieve similar performance benefits for
$Application if you call $Application->Lock() in your 
global.asa's Script_OnStart.

=head2 Low MaxClients

Set your MaxClients low, such that if you have that
many httpd servers running, which will happen on busy site,
your system will not start swapping to disk because of 
excessive RAM usage.  Typical settings are less than 100
even with 1 gig RAM!  To handle more client connections,
look into a dual server, mod_proxy front end.

=head2 High MaxRequestsPerChild

Set your max requests per child thread or process (in httpd.conf) high, 
so that ASP scripts have a better chance being cached, which happens after 
they are first compiled.  You will also avoid the process fork penalty on 
UNIX systems.  Somewhere between 50 - 500 is probably pretty good.
You do not want to set this too high though or you will risk having
your web processes use too much RAM.  One may use Apache::SizeLimit
or Apache::GTopLimit to optimally tune MaxRequestsPerChild at runtime.

=head2 Precompile Modules

For those modules that your Apache::ASP application uses,
make sure that they are loaded in your sites startup.pl
file, or loaded with PerlModule in your httpd.conf, so 
that your modules are compiled pre-fork in the parent httpd.

=head2 Precompile Scripts

Precompile your scripts by using the Apache::ASP->Loader() routine
documented below.  This will at least save the first user hitting 
a script from suffering compile time lag.  On UNIX, precompiling scripts
upon server startup allows this code to be shared with forked child
www servers, so you reduce overall memory usage, and use less CPU 
compiling scripts for each separate www server process.  These 
savings could be significant.  On a PII300 Solaris x86, it takes a couple seconds
to compile 28 scripts upon server startup, with an average of 50K RAM
per compiled script, and this savings is passed on to the ALL child httpd 
servers, so total savings would be 50Kx28x20(MaxClients)=28M!

Apache::ASP->Loader() can be called to precompile scripts and
even entire ASP applications at server startup.  Note 
also that in modperl, you can precompile modules with the 
PerlModule config directive, which is highly recommended.

 Apache::ASP->Loader($path, $pattern, %config)

This routine takes a file or directory as its first argument.  If
a file, that file will be compiled.  If a directory, that directory
will be recursed, and all files in it whose file name matches $pattern
will be compiled.  $pattern defaults to .*, which says that all scripts
in a directory will be compiled by default.  

The %config args, are the config options that you may want set that affect 
compilation.  These options include: Debug, Global, GlobalPackage, 
DynamicIncludes, IncludesDir, InodeNames, PodComments, StatINC, StatINCMatch, UseStrict, 
XMLSubsPerlArgs, XMLSubsMatch, and XMLSubsStrict. If your scripts are later run 
with different config options, your scripts may have to be recompiled.

Here is an example of use in a *.conf file:

 <Perl> 
 Apache::ASP->Loader(
	'/usr/local/proj/site', "(asp|htm)\$", 
	'Global' => '/proj/perllib',
	'Debug' => -3, # see system output when starting apache

	# OPTIONAL configs if you use them in your apache configuration
	# these settings affect how the scripts are compiled and loaded
	'GlobalPackage' => 'SomePackageName',
	'DynamicIncludes' => 1,	
	'StatINC' => 1,		
        'StatINCMatch' => 'My',
        'UseStrict' => 1,
        'XMLSubsMatch' => 'my:\w+',
        'XMLSubsStrict' => 0 || 1,
	);
 </Perl>

This config section tells the server to compile all scripts
in c:/proj/site that end in asp or htm, and print debugging
output so you can see it work.  It also sets the Global directory
to be /proj/perllib, which needs to be the same as your real config
since scripts are cached uniquely by their Global directory.  You will 
probably want to use this on a production server, unless you cannot 
afford the extra startup time.

To see precompiling in action, set Debug to 1 for the Loader() and
for your application in general and watch your error_log for 
messages indicating scripts being cached.

=head2 No .htaccess or StatINC

Don't use .htaccess files or the StatINC setting in a production system
as there are many more files touched per request using these features.  I've
seen performance slow down by half because of using these.  For eliminating
the .htaccess file, move settings into *.conf Apache files.

Instead of StatINC, try using the StatINCMatch config, which 
will check a small subset of perl libraries for changes.  This
config is fine for a production environment, and if used well
might only incur a 10-20% performance penalty, depending on the
number of modules your system loads in all, as each module
needs to be checked for changes on a per request basis.

=head2 Turn off Debugging

Turn off system debugging by setting Debug to 0-3.  Having the system 
debug config option on slows things down immensely, but can be useful
when troubleshooting your application.  System level debugging is 
settings -3 through -1, where user level debugging is 1 to 3.  User level
debugging is much more light weight depending on how many $Reponse->Debug()
statements you use in your program, and you may want to leave it on.

=head2 Memory Sparing, NoCache

If you have a lot (1000's+) of scripts, and limited memory, set NoCache to 1,
so that compiled scripts are not cached in memory.  You lose about
10-15% in speed for small scripts, but save at least 10K RAM per cached
script.  These numbers are very rough and will largely depend on the size
of your scripts and includes.

=head2 Resource Limits

Make sure your web processes do not use too many resources
like CPU or RAM with the handy Apache::Resource module.
Such a config might look like:

 PerlModule Apache::Resource
 PerlSetEnv PERL_RLIMIT_CPU  1000
 PerlSetEnv PERL_RLIMIT_DATA 60:60

If ever a web process should begin to take more than 60M ram
or use more than 1000 CPU seconds, it will be killed by 
the OS this way.  You only want to use this configuration
to protect against runaway processes and web program errors,
not for terminating a normally functioning system, so set
these limits HIGH!

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3), MLDBM(3), HTTP::Date(3), CGI(3),
Win32::OLE(3)

=head1 NOTES

Many thanks to those who helped me make this module a reality.
With Apache + ASP + Perl, web development could not be better!

Special thanks go to my father Kevin & wife Lina for their 
love and support through it all, and without whom none of it
would have been possible.

Other honorable mentions include:

 !! Doug MacEachern, for moral support and of course mod_perl
 :) Helmut Zeilinger, Skylos, John Drago, and Warren Young for their help in the community
 :) Randy Kobes, for the win32 binaries, and for always being the epitome of helpfulness
 :) Francesco Pasqualini, for bug fixes with stand alone CGI mode on Win32
 :) Szymon Juraszczyk, for better ContentType handling for settings like Clean.
 :) Oleg Kobyakovskiy, for identifying the double Session_OnEnd cleanup bug.
 :) Peter Galbavy, for reporting numerous bugs and maintaining the OpenBSD port.
 :) Richard Curtis, for reporting and working through interesting module 
    loading issues under mod_perl2 & apache2, and pushing on the file upload API.
 :) Rune Henssel, for catching a major bug shortly after 2.47 release,
    and going to great lengths to get me reproducing the bug quickly.
 :) Broc, for keeping things filter aware, which broke in 2.45,
    & much help on the list.
 :) Manabu Higashida, for fixes to work under perl 5.8.0
 :) Slaven Rezic, for suggestions on smoother CPAN installation
 :) Mitsunobu Ozato, for working on a japanese translation of the site & docs.
 :) Eamon Daly for persistence in resolving a MailErrors bug.
 :) Gert, for help on the mailing list, and pushing the limits of use on Win32 
    in addition to XSLT.
 :) Maurice Aubrey, for one of the early fixes to the long file name problem.
 :) Tom Lancaster, for pushing the $Server->Mail API and general API discussion.
 :) Ross Thomas, for pushing into areas so far unexplored.
 :) Harald Kreuzer, for bug discovery & subsequent testing in the 2.25 era.
 :) Michael Buschauer for his extreme work with XSLT.
 :) Dariusz Pietrzak for a nice parser optimization.
 :) Ime Smits, for his inode patch facilitating cross site code reuse, and
    some nice performance enhancements adding another 1-2% speed.
 :) Michael Davis, for easier CPAN installation.
 :) Brian Wheeler, for keeping up with the Apache::Filter times,
    and pulling off filtering ASP->AxKit.
 :) Ged Haywood, for his great help on the list & professionally.
 :) Vee McMillen, for OSS patience & understanding.
 :) Craig Samuel, at LRN, for his faith in open source for his LCEC.
 :) Geert Josten, for his wonderful work on XML::XSLT
 :) Gerald Richter, for his Embperl, collaboration and competition!
 :) Stas Bekman, for his beloved guide, and keeping us all worldly.
 :) Matt Sergeant, again, for ever the excellent XML critique.
 :) Remi Fasol + Serge Sozonoff who inspired cookieless sessions.
 :) Matt Arnold, for the excellent graphics !
 :) Adi, who thought to have full admin control over sessions
 :) Dmitry Beransky, for sharable web application includes, ASP on the big.
 :) Russell Weiss again, for finding the internal session garbage collection 
    behaving badly with DB_File sensitive i/o flushing requirements.
 :) Tony Merc Mobily, inspiring tweaks to compile scripts 10 times faster
 :) Paul Linder, who is Mr. Clean... not just the code, its faster too !
    Boy was that just the beginning.  Work with him later facilitated better
    session management and XMLSubsMatch custom tag technology.
 :) Russell Weiss, for being every so "strict" about his code.
 :) Bill McKinnon, who understands the finer points of running a web site.
 :) Richard Rossi, for his need for speed & boldly testing dynamic includes.
 :) Greg Stark, for endless enthusiasm, pushing the module to its limits.
 :) Marc Spencer, who brainstormed dynamic includes.
 :) Doug Silver, for finding most of the bugs.
 :) Darren Gibbons, the biggest cookie-monster I have ever known.
 :) Ken Williams, for great teamwork bringing full SSI to the table
 :) Matt Sergeant, for his great tutorial on PerlScript and love of ASP
 :) Jeff Groves, who put a STOP to user stop button woes
 :) Alan Sparks, for knowing when size is more important than speed
 :) Lincoln Stein, for his blessed CGI.pm module
 :) Michael Rothwell, for his love of Session hacking
 :) Francesco Pasqualini, for bringing ASP to CGI
 :) Bryan Murphy, for being a PerlScript wiz
 :) Lupe Christoph, for his immaculate and stubborn testing skills
 :) Ryan Whelan, for boldly testing on Unix in the early infancy of ASP

=head1 SUPPORT

=head2 COMMUNITY

=item Mailing List Archives

Try the Apache::ASP mailing list archive first when working
through an issue as others may have had the same question
as you, then try the mod_perl list archives since often
problems working with Apache::ASP are really mod_perl ones.

The Apache::ASP mailing list archives are located at:

 http://groups.yahoo.com/group/apache-asp/
 http://www.mail-archive.com/asp%40perl.apache.org/

The mod_perl mailing list archives are located at:

 http://forum.swarthmore.edu/epigone/modperl
 http://www.egroups.com/group/modperl/

=item Mailing List

Please subscribe to the Apache::ASP mailing list
by sending an email to asp-subscribe[at]perl.apache.org
and send your questions or comments to the list
after your subscription is confirmed.

To unsubscribe from the Apache::ASP mailing list,
just send an email to asp-unsubscribe[at]perl.apache.org

If you think this is a mod_perl specific issue, you can
send your question to modperl[at]apache.org

=item Donations

Apache::ASP is freely distributed under the terms of the GPL license 
( see the LICENSE section ). If you would like to donate time to 
the project, please get involved on the Apache::ASP Mailing List,
and submit ideas, bug fixes and patches for the core system,
and perhaps most importantly to simply support others in learning
the ins and outs of the software.

=head2 COMMERCIAL

If you would like commercial support for Apache::ASP, please
check out any of the following listed companies.  Note that 
this is not an endorsement, and if you would like your company
listed here, please email asp-dev [at] chamas.com with your information.

=item AlterCom

We use, host and support mod_perl. We would love to be able to help 
anyone with their mod_perl Apache::ASP needs.  Our mod_perl hosting is $24.95 mo.

  http://altercom.com/home.html

=item The Cyberchute Connection

Our hosting services support Apache:ASP along with Mod_Perl, PHP and MySQL.

  http://www.Cyberchute.com

=item GrokThis.net

Web hosting provider.  Specializing in mod_perl and mod_python
hosting,  we allow users to edit their own Apache configuration files
and run their own Apache servers.

  http://grokthis.net

=item OmniTI

OmniTI supports Apache and mod_perl (including Apache::ASP) and offers competitive pricing for both hourly and project-based jobs. OmniTI has extensive experience managing and maintaining both large and small projects. Our services range from short-term consulting to project-based development, and include ongoing maintenance and hosting.

  http://www.omniti.com

=item TUX IT AG

Main business is implementing and maintaining infrastructure for big
websites and portals, as well as developing web applications for our
customers (Apache, Apache::ASP, PHP, Perl, MySQL, etc.)

The prices for our service are about 900 EUR per day which is negotiable
(for longer projects, etc.).

  http://www.tuxit.de

=head1 SITES USING

What follows is a list of public sites that are using 
Apache::ASP.  If you use the software for your site, and 
would like to show your support of the software by being listed, 
please send your link to asp-dev [at] chamas.com

For a list of testimonials of those using Apache::ASP, please see the TESTIMONIALS section.

        Zapisy - Testy
        http://www.ch.pwr.wroc.pl/~bruno/testy/

        SalesJobs.com
        http://www.salesjobs.com

        FreeLotto
        http://www.freelotto.com

        Hungarian TOP1000
        http://www.hungariantop1000.com

        Hungarian Registry
        http://www.hunreg.com

        Kepeslap.com
        http://www.kepeslap.com

        yourpostcardsite.com
        http://www.yourpostcardsite.com

        WebTime
        http://webtime-project.net

        Meet-O-Matic
        http://meetomatic.com/about.asp

        Apache Hello World Benchmarks
        http://chamas.com/bench/

        AlterCom, Advanced Web Hosting
        http://altercom.com/

        AmericanGamers.com
        http://www.AmericanGamers.com/

        ESSTECwebservices
        http://www.esstec.be/

        SQLRef
        http://comclub.dyndns.org:8081/sqlref/

        Bouygues Telecom Enterprises
        http://www.b2bouygtel.com

        Alumni.NET
	http://www.alumni.net

        Anime Wallpapers dot com
        http://www.animewallpapers.com/

	Chamas Enterprises Inc.		
	http://www.chamas.com

	Cine.gr
	http://www.cine.gr

	Condo-Mart Web Service
	http://www.condo-mart.com 

        Discountclick.com
        http://www.discountclick.com/

	HCST
	http://www.hcst.net

	International Telecommunication Union
	http://www.itu.int

	Integra
	http://www.integra.ru/

	Internetowa Gielda Samochodowa		
	http://www.gielda.szczecin.pl

        Money FM
        http://www.moneyfm.gr

	Motorsport.com
	http://www.motorsport.com

	MLS of Greater Cincinnati
	http://www.cincymls.com

	NodeWorks Link Checker
	http://www.nodeworks.com

	OnTheWeb Services
	http://www.ontheweb.nu

	Prices for Antiques
	http://www.p4a.com

	redhat.com | support
	http://www.redhat.com/apps/support/

	Samara.RU
	http://portal.samara.ru/

	Spotlight
	http://www.spotlight.com.au

	USCD Electrical & Computer Engineering
	http://ece-local.ucsd.edu

=head1 TESTIMONIALS

Here are testimonials from those using Apache::ASP.
If you use this software and would like to show your 
support please send your testimonial to Apache::ASP mailing 
list at asp[at]perl.apache.org and indicate that we can 
post it to the web site.

For a list of sites using Apache::ASP, please see the SITES USING section.

=item Red Hat

=begin html

<a href=http://www.redhat.com><img src=redhat_logo.gif border=0></a>

=end html

We're using Apache::ASP on www.redhat.com. We find Apache::ASP very
easy to use, and it's quick for new developers to get up to speed with
it, given that many people have already been exposed to the ASP object
model that Apache::ASP is based on. 

The documentation is comprehensive and easy to understand, and the
community and maintainer have been very helpful whenever we've had
questions.

  -- Tom Lancaster, Red Hat

=item D. L. Fox

I had programmed in Perl for some time ... but, 
since I also knew VB, I had switched to VB in IIS-ASP for 
web stuff because of its ease of use in embedding code
with HTML ...  When I discovered
Apache-ASP, it was like a dream come true.  I would much rather code in Perl
than any other language.  Thanks for such a fine product!

=item HOSTING 321, LLC.

After discontinuing Windows-based hosting due to the high cost of software, 
our clients are thrilled with Apache::ASP and they swear ASP it's faster 
than before. Installation was a snap on our 25-server web farm with a small 
shell script and everything is running perfectly! The documentation is 
very comprehensive and everyone has been very helpful during this migration.

Thank you!

 -- Richard Ward, HOSTING 321, LLC.

=item Concept Online Ltd.

=begin html

<a href=http://www.conceptonline.com><img src=concept_online.gif border=0></a>

=end html

I would like to say that your ASP module rocks :-) We have practically stopped developing in anything else about half a year ago, and are now using Apache::ASP extensively. I just love Perl, and whereever we are not "forced" to use JSP, we chose ASP. It is fast, reliable, versatile, documented in a way that is the best for professionals - so thank you for writting and maintaining it!

  -- Csongor Fagyal, Concept Online Ltd.

=item WebTime

=begin html

<a href="http://webtime-project.net"><img border=0 src="webtimelogo.jpg"></a>

=end html

As we have seen with WebTime, Apache::ASP is not only good  for the
development of website, but also for the development of webtools. Since
I first discoverd it, I made it a must-have in my society by taking
traditional PHP users to the world of perl afficionados.

Having the possibility to use Apache::ASP with mod_perl or mod_cgi make
it constraintless to use because of CGI's universality and perl's
portability.

  -- Grégoire Lejeune

=item David Kulp

First, I just want to say that I am very very impressed with Apache::ASP.  I
just want to gush with praise after looking at many other implementations of
perl embedded code and being very underwhelmed.  This is so damn slick and
clean.  Kudos! ...

... I'm very pleased how quickly I've been able to mock
up the application.  I've been writing Perl CGI off and on since 1993(!)
and I can tell you that Apache::ASP is a pleasure.  (Last year I tried
Zope and just about threw my computer out the window.)

  -- David Kulp

=item MFM Commmunication Software, Inc.

=begin html

<table border=0><tr><td>
<a href="http://www.mfm.com"><img src="communication_software.gif" border=0></a>
<p>
<a href=http://www.huff.com/>HUFF Realty</a>
<br>
<a href=http://www.starone.com/>Star One Realtors</a>
<br>
<a href=http://www.comey.com/>Comey & Shepherd Realtors</a>
<br>
<a href=http://www.unlimitedrealestate.net/>RE/MAX Unlimited Realtors</a>
<br>
<a href=http://www.cincinnatibuilders.com/>Cincinnati Builders</a>
<br>
<a href=http://www.airportdays.com/>Blue Ash Airport Days Airshow</a>
</td></tr></table>

=end html

Working in a team environment where you have HTML coders and perl
coders, Apache::ASP makes it easy for the HTML folks to change the look
of the page without knowing perl. Using Apache::ASP (instead of another
embedded perl solution) allows the HTML jockeys to use a variety of HTML
tools that understand ASP, which reduces the amount of code they break
when editing the HTML.  Using Apache::ASP instead of M$ ASP allows us to
use perl (far superior to VBScript) and Apache (far superior to IIS).

We've been very pleased with Apache::ASP and its support.

=item Planet of Music

Apache::ASP has been a great tool.  Just a little
background.... the whole site had been in cgi flat files when I started
here.  I was looking for a technology that would allow me to write the
objects and NEVER invoke CGI.pm... I found it and hopefuly I will be able to
implement this every site I go to.

When I got here there was a huge argument about needing a game engine
and I belive this has been the key... Games are approx. 10 time faster than
before. The games don't break anylonger. All in all a great tool for
advancement.

  -- JC Fant IV

=item Cine.gr

=begin html

<a href="http://www.cine.gr"><img src="cine.gr.gif" border=0></a>

=end html

...we ported our biggest yet ASP site from IIS (well, actually rewrote),
Cine.gr and it is a killer site.  In some cases, the whole thing got almost 25 (no typo) times faster...
None of this would ever be possible without Apache::ASP (I do not ever want to write ``print "<HTML>\n";''
again).

=head1 RESOURCES

Here are some important resources listed related to 
the use of Apache::ASP for publishing web applications.
If you have any more to suggest, please email the Apache::ASP list
at asp[at]perl.apache.org

=head2 Articles

       Apache::ASP Introduction ( #1 in 3 part series )
       http://www.apache-asp.org/articles/perlmonth1_intro.html

       Apache::ASP Site Building ( #2 in 3 part series )
       http://www.apache-asp.org/articles/perlmonth2_build.html

       Apache::ASP Site Tuning ( #3 in 3 part series )
       http://www.apache-asp.org/articles/perlmonth3_tune.html

       Embedded Perl ( part of a series on Perl )
       http://www.wdvl.com/Authoring/Languages/Perl/PerlfortheWeb/index15.html

=head2 Benchmarking

       Apache Hello World Benchmarks
       http://chamas.com/bench/

=head2 Books

       mod_perl "Eagle" Book
       http://www.modperl.com

       mod_perl Developer's Cookbook
       http://www.modperlcookbook.org

       Programming the Perl DBI
       http://www.oreilly.com/catalog/perldbi/

=head2 Presentations

       Apache::ASP Tutorial, 2000 Open Source Convention ( PowerPoint )
       http://www.chamas.com/asp/OSS_convention_2000.pps

       Advanced Apache::ASP Tutorial, 2001 Open Source Convention ( Zipped PDF )
       http://www.chamas.com/asp/OSS_convention_2001.zip

       Advanced Apache::ASP Tutorial, 2001 Open Source Convention ( PDF )
       http://www.chamas.com/asp/OSS_convention_2001.pdf

=head2 Reference Cards

        Apache & mod_perl Reference Cards
        http://www.refcards.com/

=head2 Web Sites

	mod_perl Apache web module
	http://perl.apache.org

	mod_perl Guide
	http://perl.apache.org/guide/

	Perl Programming Language
	http://www.perl.com

	Apache Web Server
	http://www.apache.org
 
=head1 TODO

There is no specific time frame in which these things will be 
implemented.  Please let me know if any of these is of particular
interest to you, and I will give it higher priority.

=head2 WILL BE DONE 

 + Database storage of $Session & $Application, so web clusters 
   may scale better than the current NFS/CIFS StateDir implementation
   allows, maybe via Apache::Session.
 + Sample Apache::ASP applications beyond ./site/eg
 + More caching options like $Server->Cache for user cache
   and $Response->Cache for page caching
 + Caching guide

=head2 MAY BE DONE

 + VBScript, ECMAScript or JavaScript interpreters
 + Dumping state of Apache::ASP during an error, and being
   able to go through it with the perl debugger.

=head1 CHANGES

Apache::ASP has been in development since 1998, and 
was production ready since its .02 release.  Releases
are always used in a production setting before being
made publically available.

In July 2000, the version numbers of releases went 
from .19 to 1.9 which is more relevant to software development
outside the perl community.  Where a .10 perl module usually
means first production ready release, this would be the
equivalent of a 1.0 release for other kinds of software.

 + = improvement   - = bug fix    (d) = documentations

=item $VERSION = 2.62; $DATE="2011/08/16"

 - Fixed 'application/x-www-form-urlencoded' for AJAX POSTs post
   Firefox 3.x

 + First sourceforge.net hosted version

 + Incremented version number to actually match SVN branch tag

 + Switched to Big-endian date format in the documentation.
   Less chance of misunderstandings

=item $VERSION = 2.61; $DATE="05/24/2008"

 - updated for more recent mod_perl 2 environment to trigger correct loading of modules

 + loads modules in a backwards compatible way for older versions of mod_perl 1.99_07 to 1.99_09

 + license changes from GPL to Perl Artistic License

=item $VERSION = 2.59; $DATE="05/23/2005"

 + added "use bytes" to Response object to calculate Content-Length
   correctly for UTF8 data, which should require therefore at least
   perl version 5.6 installed

 + updated to work with latest mod_perl 2.0 module naming convention,
   thanks to Randy Kobes for patch

 + examples now exclude usage of Apache::Filter & Apache::SSI under mod_perl 2.0

=item $VERSION = 2.57; $DATE="01/29/2004"

 - $Server->Transfer will update $0 correctly

 - return 0 for mod_perl handler to work with latest mod_perl 2 release
   when we were returning 200 ( HTTP_OK ) before

 - fixed bug in $Server->URL when called like $Server->URL($url)
   without parameters.  Its not clear which perl versions this bug 
   affected.

=item $VERSION = 2.55; $DATE="08/09/2003"

 - Bug fixes for running on standalone CGI mode on Win32 submitted
   by Francesco Pasqualini

 + Added Apache::ASP::Request::BINMODE for binmode() being
   called on STDIN after STDIN is tied to $Request object

 + New RequestBinaryRead configuration created, may be turned off
   to prevent $Request object from reading POST data

 ++ mod_perl 2 optmizations, there was a large code impact on this,
   as much code was restructured to reduce the differences between
   mod_perl 1 and mod_perl 2, most importantly, Apache::compat is
   no longer used

 + preloaded CGI for file uploads in the mod_perl environment

 - When XSLT config is set, $Response->Redirect() should work now
   Thanks to Marcus Zoller for pointing problem out

 + Added CookieDomain setting, documented, and added test to cover 
   it in t/cookies.t . Setting suggested by Uwe Riehm, who nicely 
   submitted some code for this.

=item $VERSION = 2.53; $DATE="04/10/2003"

 + XMLSubs tags with "-" in them will have "-" replaced with "_" or underscore, so a
   tag like <my:render-table /> will be translated to &my::render_table() ... tags with
   - in them are common in extended XML syntaxes, but perl subs cannot have - in them only.

 + Clean setting now works on output when $Response->{ContentType} begins with text/html;
   like "text/html; charset=iso-8859-2" ... before Clean would only work on output marked
   with ContentType text/html.  Thanks to Szymon Juraszczyk for recommending fix.

 --Fixed a bug which would cause Session_OnEnd to be called twice on sessions in a certain case,
   particularly when an old expired session gets reused by and web browser... this bug was
   a result of a incomplete session cleanup method in this case.  Thanks to Oleg Kobyakovskiy 
   for reporting this bug.  Added test in t/session_events.t to cover this problem going forward.

 - Compile errors from Apache::ASP->Loader() were not being reported.  They will
   be reported again now.  Thanks to Thanos Chatziathanassiou for discovering and
   documenting this bug.  Added test in t/load.t to cover this problem going forward.

 + use of chr(hex($1)) to decode URI encoded parameters instead of pack("c",hex($1))
   faster & more correct, thanks to Nikolay Melekhin for pointing out this need.

 (d) Added old perlmonth.com articles to ./site/articles in distribution
   and linked to them from the docs RESOURCES section

 (d) Updated documention for the $Application->SessionCount API

 + Scripts with named subroutines, which is warned against in the style guide,
   will not be cached to help prevent my closure problems that often
   hurt new developers working in mod_perl environments.  The downside
   is that these script will have a performance penalty having to be
   recompiled each invocation, but this will kill many closure caching 
   bugs that are hard to detect.

 - $Request->FileUpload('upload_file', 'BrowserFile') would return
   a glob before that would be the file name in scalar form.  However
   this would be interpreted as a reference incorrectly.  The fix
   is to make sure this is always a scalar by stringifying 
   this data internally.  Thanks to Richard Curtis for pointing
   out this bug.

=item $VERSION = 2.51; $DATE="02/10/2003"

 + added t/session_query_parse.t test to cover use of SessionQueryParse
   and $Server->URL APIs

 - Fixed duplicate "&" bug associated with using $Server->URL 
   and SessionQueryParse together

 + Patch to allow $Server->URL() to be called multiple times on the same URL
   as in $Server->URL($Server->URL($url, \%params), \%more_params)

 (d) Added new testimonials & sites & created a separate testimonials page.

 - SessionQueryParse will now add to &amp; to the query strings
   embedded in the HTML, instead of & for proper HTML generation.
   Thanks to Peter Galbavy for pointing out and Thanos Chatziathanassiou
   for suggesting the fix.

 - $Response->{ContentType} set to text/html for developer error reporting,
   in case this was set to something else before the error occured.
   Thanks to Philip Mak for reporting.

 - Couple of minor bug fixes under PerlWarn use, thanks Peter Galbavy
   for reporting.

 + Added automatic load of "use Apache2" for compat with mod_perl2 
   request objects when Apache::ASP is loaded via "PerlModule Apache::ASP"
   Thanks to Richard Curtis for reporting bug & subsequent testing.

 - When GlobalPackage config changes, but global.asa has not, global.asa
   will be recompiled anyway to update the GlobalPackage correctly.
   Changing GlobalPackage before would cause errors if global.asa was
   already compiled.

 ++ For ANY PerlSetVar type config, OFF/Off/off will be assumed 
    to have value of 0 for that setting.  Before, only a couple settings
    had this semantics, but they all do now for consistency.

 - Fix for InodeNames config on OpenBSD, or any OS that might have
   a device # of 0 for the file being stat()'d, thanks to Peter Galbavy
   for bug report.

 ++ Total XSLT speedups, 5-10% on large XSLT, 10-15% on small XSLT

 + bypass meta data check like expires for XSLT Cache() API use
   because XSLT tranformations don't expire, saves hit to cache dbm
   for meta data

 + use of direct Apache::ASP::State methods like FETCH/STORE
   in Cache() layer so we don't have to go through slower tied interface.
   This will speed up XSLT & and include output caching mostly.

 + minor optimizations for speed & memory usage

=item $VERSION = 2.49; $DATE="11/10/2002"

 -- bug introduced in 2.47 cached script compilations for executing
    scripts ( not includes ) of the same name in different directories
    for the same Global/GlobalPackage config for an application.
    Fix was to remove optimization that caused problem, and
    created test case t/same_name.t to cover bug.

=item $VERSION = 2.47; $DATE="11/06/2002"

 ++ Runtime speed enhancements for 15-20% improvement including:
   + INTERNAL API ReadFile() now returns scalar ref as memory optimization
   + cache InodeNames config setting in ASP object now for common lookups
   + removed CompileChecksum() INTERNAL API, since it was an unnecesary
     method decomposition along a common code path
   + removed IsChanged() INTERNAL API since compiling of scripts
     is now handled by CompileInclude() which does this functionality already
   + removed unnecessary decomp of IncludesChanged() INTERNAL API, which was along
     critical code path
   + do not call INTERNAL SearchDirs() API when compiling base script
     since we have already validated its path earlier
   + Use stat(_) type shortcut for stat() & -X calls where possible
   + Moved @INC initilization up to handler() & consolidated with $INCDir lib
   + removed useless Apache::ASP::Collection::DESTROY
   + removed useless Apache::ASP::Server::DESTROY
   + removed useless Apache::ASP::GlobalASA::DESTROY
   + removed useless Apache::ASP::Response::DESTROY

 - Default path for $Response->{Cookies} was from CookiePath
   config, but this was incorrect as CookiePath config is only
   for $Session cookie, so now path for $Response->{Cookies}
   defaults to /

 - Fixed bug where global.asa events would get undefined with
   StatINC and GlobalPackage set when the GlobalPackage library
   changed & get reloaded.

 (d) Documented long time config NoCache.

 -- Fixed use with Apache::Filter, capable as both source
    and destination filter.  Added ./site/eg/filter.filter example
    to demonstrate these abilities.

 + Use $r->err_headers_out->add Apache::Table API for cookies 
   now instead of $r->cgi_header_out.  Added t/cookies.t test to 
   cover new code path as well as general $Response->Cookies API.
   Also make cookies headers sorted by cookie and dictionary key 
   while building headers for repeatable behavior, this latter was 
   to facilitate testing.

 - fixed $Server->Mail error_log output when failing to connect
   to SMTP server.

 + added tests to cover UniquePackages & NoCache configs since this
   config logic was updated

 + made deprecated warnings for use of certain $Response->Member
   calls more loudly write to error_log, so I can remove the AUTOLOAD
   for Response one day

 - Probably fixed behavior in CgiHeaders, at least under perl 5.8.0, and
   added t/cgi_headers.t to cover this config.

 + removed $Apache::ASP::CompressGzip setting ability, used to possibly
   set CompressGzip in the module before, not documented anyway

 + removed $Apache::ASP::Filter setting ability to set Filter globally, 
   not documented anyway

 + removed old work around for setting ServerStarting to 0
   at runtime, which was bad for Apache::DBI on win32 a long
   time ago:

    $Apache::ServerStarting and $Apache::ServerStarting = 0;

   If this code is still needed in Apache::ASP->handler() let
   me know.

 + check to make sure data in internal database is a HASH ref
   before using it for session garbage collection.  This is to
   help prevent against internal database corruption in a 
   network share that does not support flock() file locking.

 + For new XMLSubs ASP type <%= %> argument interpolation
   activated with XMLSubsPerlArgs 0, data references can now
   be passed in addition to SCALAR/string references, so one
   can pass an object reference like so:

     <my:tag value="<%= $Object %>" />

   This will only work as long as the variable interpolation <%= %>
   are flushed against the containing " " or ' ', or else the object
   reference will be stringified when it is concatenated with 
   the rest of the data.

   Testing for this feature was added to ./t/xmlsubs_aspargs.t

   This feature is still experimental, and its interface may change.
   However it is slated for the 3.0 release as default method,
   so feedback is appreciated.

 + For new XMLSubs ASP type <%= %> argument interpolation
   activated with XMLSubsPerlArgs 0, <% %> will no longer work,
   just <%= %>, as in 

     <my:tag value="some value <%= $value %> more data" />

   This feature is still experimental, and its interface may change.
   However it is slated for the 3.0 release as default method,
   so feedback is appreciated.

=item $VERSION = 2.45; $DATE="10/13/2002"

 ++New XMLSubsPerlArgs config, default 1, indicates how 
  XMLSubs arguments have always been parsed.  If set to 0,
  will enable new XMLSubs args that are more ASP like with
  <%= %> for dynamic interpolation, such as:

    <my:xmlsub arg="<%= $data %>" arg2="text <%= $data2 %>" />
 
  Settings XMLSubsPerlArgs to 0 is experimental for now, but
  will become the default by Apache::ASP version 3.0

 ++Optimization for static HTML/XML files that are served up 
  via Apache::ASP so that they are not compiled into perl subroutines
  first.  This makes especially native XSLT both faster & take
  less memory to serve, before XSL & XML files being transformed
  by XSLT would both be compiled as normal ASP script first, so 
  now this will happen if they really are ASP scripts with embedded
  <% %> code blocks & XMLSubs being executed.

 +Consolidate some config data for Apache::ASP->Loader to use
  globals in @Apache::ASP::CompileChecksumKeys to know which 
  config data is important for precompiling ASP scripts.

 +Further streamlined code compilation.  Now both base
  scripts and includes use the internal CompileInclude() API
  to generate code.

 -Fixed runtime HTML error output when Debug is set to -2/2,
  so that script correctly again gets rendered in final perl form.
  Added compile time error output to ./site/eg/syntax_error.htm
  when a special link is clicked for a quick visual test.

 -Cleaned up some bad coding practices in ./site/eg/global.asa
  associated changes in other example files.  Comment example
  global.asa some for the first time reader

 -DemoASP.pm examples module needed "use strict" fix, thanks
  to Allan Vest for bug report

 --$rv = $Response->Include({ File => ..., Cache => 1});
  now works to get the first returned value fetched from
  the cache.  Before, because a list was always returned,
  $rv would have been equal to the number of items returned,
  even if the return value list has just one element.

 (d) added site/robots.txt file with just a comment for
     search engine indexing

 -fixed ./site/eg/binary_write.htm to not use 
  $Response->{ContentLength} because it does not exist.
  Fixed it to use $Response->AddHeader now instead  

=item $VERSION = 2.41; $DATE="09/29/2002"

 -Removed CVS Revision tag from Apache::ASP::Date, which 
  was causing bad revision numbers in CPAN after CVS integration
  of Apache::ASP

 +removed cgi/asp link to ../asp-perl from distribution.  This
  link was for the deprecated asp script which is now asp-perl

=item $VERSION = 2.39; $DATE="09/10/2002"

 -Turn off $^W explicitly before reloading global.asa.  Reloading
  global.asa when $^W is set will trigger subroutine redefinition
  warnings.  Reloading global.asa should occur without any problems
  under normal usage of the system, thus this work around.

  This fix is important to UseStrict functionality because warnings
  automatically become thrown as die() errors with UseStrict enabled,
  so we have to disable normal soft warnings here.

 -$Response->Include() runtime errors now throw a die() that
  can be trapped.  This was old functionality that has been restored.
  Other compile time errors should still trigger a hard error
  like script compilation, global.asa, or $Response->Include()
  without an eval()

 +Some better error handling with Debug 3 or -3 set, cleaned
  up developer errors messages somewhat.

=item $VERSION = 2.37; $DATE="07/03/2002"

 -Fixed the testing directory structures for t/long_names.t
  so that tar software like Archive::Tar & Solaris tar that
  have problems with long file names will still be able 
  to untar distribution successfully.  Now t/long_names.t
  generates its testing directory structures at runtime.

 -Fixes for "make test" to work under perl 5.8.0 RC2, 
  courtesy of Manabu Higashida

 +SessionQueryForce setting created for disabling use of cookies
  for $Session session-id passing, rather requiring use of SessionQuery*
  functionality for session-id passing via URL query string.

  By default, even when SessionQuery* options are used, cookies will
  be used if available with SessionQuery* functionality acting only
  as a backup, so this makes it so that cookies will never be used.

 +Escape ' with HTMLEncode() to &#39;

 -Trying to fix t/server_mail.t to work better for platforms
  that it should skip testing on.  Updated t/server.t test case.

 +Remove exit() from Makefile.PL so CPAN.pm's automatic
  follow prereq mechanism works correctly.  Thanks to Slaven Rezic
  for pointing this out.

 +Added Apache::compat loading in mod_perl environment for better
  mod_perl 2.0 support.

=item $VERSION = 2.35; $DATE="05/30/2002"

 +Destroy better $Server & $Response objects so that my 
  closure references to these to not attempt to work in the future 
  against invalid internal data. There was enough data left in these 
  old objects to make debugging the my closure problem confusing, where 
  it looked like the ASP object state became invalid.

 +Added system debug diagnostics to inspect StateManager group cleanup

 (d) Documentation update about flock() work around for 
  Win95/Win98/WinMe systems, confirmed by Rex Arul

 (d) Documentation/site build bug found by Mitsunobu Ozato, 
  where <% %> not being escaped correctly with $Server->HTMLEncode().
  New japanese documentation project started by him 
  at http://sourceforge.jp/projects/apache-asp-jp/ 

 -InitPackageGlobals() called after new Apache::ASP object created so 
  core system templates can be compiled even when there was a runtime
  compilation error of user templates.  Bug fix needed pointed out by
  Eamon Daly

=item $VERSION = 2.33; $DATE="04/29/2002"

 - fixed up t/server_mail.t test to skip if a sendmail server
   is not available on localhost.  We only want the test to run
   if there is a server to test against.

 + removed cgi/asp script, just a symlink now to the ./asp-perl script
   which in this way deprecates it.  I had it hard linked, but the 
   distribution did not untar very well on win32 platform.

 + Reordered the modules in Bundle::Apache::ASP for a cleaner install.

 - Fixed bug where XMLSubs where removing <?xml version ... ?> tag
   when it was needed in XSLT mode.

 + $Server->Mail({ CC => '...', BCC => '...' }), now works to send
   CC & BCC headers/recipients.

 + Removed $Apache::ASP::Register definition which defined the current
   executing Apache::ASP object.  Only one part of the application was
   using it, and this has been fixed.  This would have been an unsafe
   use of globals for a threaded environment.

 + Decreased latency when doing Application_OnStart, used to sleep(1) 
   for CleanupMaster sync, but this is not necessary for Application_OnStart 
   scenario

 + Restructure code / core templates for MailErrorsTo funcationality.  
   Wrote test mail_error.t to cover this.  $ENV{REMOTE_USER} will now 
   be displayed in the MailErrorsTo message when defined from 401 basic auth.

 + $Server->RegisterCleanup should be thread safe now, as it no longer relies
   on access to @Apache::ASP::Cleanup for storing the CODE ref stack.

 + test t/inode_names.t for InodeNames and other file tests covering case
   of long file names.

 - Fixed long file name sub identifier bug.  Added test t/long_names.t.

 + CacheDir may now be set independently of StateDir.  It used to default
   to StateDir if it was set.

 ++ Decomposition of modules like Apache::ASP::Session & Apache::ASP::Application
   out of ASP.pm file.  This should make the source more developer friendly.  

   This selective code compilation also speeds up CGI requests that do not 
   need to load unneeded modules like Apache::ASP::Session, by about 50%,
   so where CGI mode ran at about 2.1 hits/sec before, now for 
   light requests that do not load $Session & $Application, requests
   run at 3.4 hits/sec, this is on a dual PIII-450 linux 2.4.x

 - Caching like for XSLTCache now works in CGI mode.  
   This was a bug that it did not before.

 + $Server->File() API added, acts as a wrapper around 
   Apache->request->filename Added test in t/server.t

 ++  *** EXPERIMENTAL / ALPHA FEATURE NOTE BEGIN ***

   New $PERLLIB/Apache/ASP/Share/ directory created to 
   hold system & user contributed components, which will be found
   on the $Server->MapInclude() path, which helps $Response->Include
   search '.',Global,IncludesDir, and now Apache::ASP::Share for
   includes to load at runtime.  

   The syntax for loading a shared include is to prefix the file
   name with Share:: as in:

    $Response->TrapInclude('Share::CORE/MailError.inc');

   New test to cover this at t/share.t

   This feature is experimental.  The naming convention may change
   and the feature may disappear altogether, so only use if you
   are interesting in experimenting with this feature & will
   provide feedback about how it works.

   *** EXPERIMENTAL / ALPHA FEATURE NOTE END ***

 + asp-perl script now uses ./asp.conf instead of ./asp.config
   for runtime configuration via %Config defined there.  Update docs
   for running in standalone CGI mode

 + Make use of MANFEST.SKIP to not publish the dev/* files anymore.

 - Script_OnEnd guaranteed to run after $Response->End, but 
   it will not run if there was an error earlier in the request.

 + lots of new test cases covering behaviour of $Response->End
   and $Response->Redirect under various conditions like XMLSubs
   and SoftRedirect and global.asa Script_OnStart

 + asp-perl will be installed into the bin executables when
   Apache::ASP is installed.  asp-perl is the command line version
   of Apache::ASP that can also be used to run script in CGI mode.
   Test case covering asp-perl functionality.

 + asp CGI/command line script now called asp-perl.  I picked this 
   name because Apache::ASP often has the name asp-perl in distributions
   of the module.

 + Apache::ASP::CGI::Test class now subclass of Apache::ASP::CGI.  To facilitate
   this Apache::ASP::CGI::init() now called OO like Apache::ASP::CGI->init()
   Fixed up places where the old style was called.  New Test class allows
   a dummy Apache request object to be built which caches header & body output
   for later inspection instead of writing it to STDOUT.

 - $Response->Redirect() under SoftRedirect 1 will not first Clear() buffer

 - $Response->Redirect() in an XMLSubs will work now ... behavior
   of $Response->Flush() being turned off in an XMLSubs was interfering with this.

 + srand() init tracking done better, thanks for patch from Ime Smits

 + Added file/directory being used for precompilation in 
   Apache::ASP->Loader($file, ...) to output like:

    [Mon Feb 04 20:19:22 2002] [error] [asp] 4215 (re)compiled 22 scripts 
      of 22 loaded for $file

   This is so that when precompiling multiple web sites
   each with different directories, one can easier see the 
   compile output relevant to the Loader() command being run.

 + better decomp of Apache::ASP site build files at ./build/* files,
   which is good should anyone look at it for ideas.

 + improved test suite to error when unintended output results from
   t/*.t test scripts.

 - () now supported in XMLSubsMatch config, added xmlsubsmatch.t test...
   specifically a config like 

     PerlSetVar (aaa|bbb):\w+ 

   should now work.  Thanks for bug report from David Kulp.

 + Added an early srand() for better $ServerID creation

 + Work around for DSO problems where $r is not always correctly 
   defined in Apache::ASP::handler().  Thanks to Tom Lear for patch.

=item $VERSION = 2.31; $DATE="01/22/2002";

 + $Server->MapInclude() API extension created to wrap up Apache::ASP::SearchDirs 
   functionality so one may do an conditional check for an include existence befor 
   executing $Response->Include().  Added API test to server.t

 + $Server->Transfer() now allows arguments like $Response->Include(), and now acts just
   as a wrapper for:

     $Response->Include($file, @args);
     $Response->End();

   added test case at t/server_transfer.t

 + Removed dependency of StatINC functionality on Apache::Symbol.  Apache::Symbol 
   is no longer required.  Added test of t/stat_inc.t for correct StatINC initialization
   for platforms where Devel::Symdump is present.

 + Better error message when $Request->Params has not been defined with RequestParams
   config & it gets used in script.  Added test case as t/request_params_none.t

 + Directories cannot now be included as scripts via $Response->Include(), added
   test case to t/include.t

 - No longer make $Response->Flush dependent on $Response->IsClientConnected() to 
   be true to write output to client.  There have been spurious errors reported
   about the new ( >= 2.25 ) IsClientConnected code, and this will limit the impact 
   of that functionality possibly not working still to those users explicitly using 
   that API.

 + $Response->AddHeader($header_name, $value) now will set $Response members
   for these headers: Content-Type, Cache-Control, Expires.  This is to avoid
   both the application & Apache::ASP sending out duplicate headers.  Added
   test cases for this to t/response.t

 + split up Bundle::Apache::ASP into that, and Bundle::Apache::ASP::Extra
   the former with just the required modules to run, and the latter 
   for extra functionality in Apache::ASP

 + new $Request->{Method} member to return $r->method of GET or POST that 
   client browser is requesting, added t/request.t sub test to cover this member.

=item $VERSION = 2.29; $DATE="11/19/2001";

 +Added some extra help text to the ./cgi/asp --help message
  to clarify how to pass arguments to a script from the command line.

 +When using $Server->Mail() API, if Content-Type header is set,
  and MIME-Version is not, then a "MIME-Version: 1.0" header will be sent
  for the email.  This is correct according to RFC 1521 which specifies
  for the first time the Content-Type: header for email documents.
  Thanks to Philip Mak for pointing out this correct behavior.

 +Made dependent on MLDBM::Sync version .25 to pass the taint_check.t test

 +Improved server_mail.t test to work with mail servers were relaying is denied

 +Added <html><body> tags to MailErrorsTo email

 --Fixed SessionCount / Session_OnEnd bug, where these things were not
  working for $Sessions that never had anything written to them.
  This bug was introduced in 2.23/2.25 release.

  There was an optimization in 2.23/2.25 where a $Session that was never
  used does not write its state lock file & dbm files to disk, only if
  it gets written too like $Session->{MARK}++.  Tracking of these NULL $Sessions 
  then is handled solely in the internal database.  For $Session garbage 
  collection though which would fire Session_OnEnd events and update 
  SessionCount, the Apache::ASP::State->GroupMembers() function was just 
  looking for state files on disk ... now it looks in the internal database 
  too for SessionID records for garbage collection.

  Added a test at ./t/session_events.t for these things.

 +Some optimizations for $Session API use.

 +Added support for XSLT via XML::LibXSLT, patch courtesy of Michael Buschauer

 -Got rid of an warning when recompiling changing includes under perl 5.6.1...
  undef($code) method did not work for this perl version, rather undef(&$code) does.
  Stopped using using Apache::Symbol for this when available.

 -Make Apache::ASP script run under perl taint checking -T for perl 5.6.1...
  $code =~ tr///; does not work to untaint here, so much use the slower:
  $code =~ /^(.*)$/s; $code = $1; method to untaint.

 -Check for inline includes changing, included in a dynamic included
  loaded at runtime via $Response->Include().  Added test case for
  this at t/include_change.t.  If an inline include of a dynamic include
  changes, the dynamic include should get recompiled now.

 -Make OK to use again with PerlTaintCheck On, with MLDBM::Sync 2.25.
  Fixed in ASP.pm, t/global.asa, and created new t/taint_check.t test script

 +Load more modules when Apache::ASP is loaded so parent will share more
  with children httpd: 
   Apache::Symbol 
   Devel::Symdump 
   Config 
   lib 
   MLDBM::Sync::SDBM_File

 +When FileUploadMax bytes is exceeded for a file upload, there will not
  be an odd error anymore resulting from $CGI::POST_MAX being triggered,
  instead the file upload input will simply be ignored via $CGI::DISABLE_UPLOADS.
  This gives the developer the opportunity to tell the user the the file upload
  was too big, as demonstrated by the ./site/eg/file_upload.asp example.

  To not let the web client POST a lot of data to your scripts as a form
  of a denial of service attack use the apache config LimitRequestBody for the 
  max limits.  You can think of PerlSetVar FileUploadMax as a soft limit, and 
  apache's LimitRequestBody as a hard limit.

 --Under certain circumstances with file upload, it seems that IsClientConnected() 
  would return an aborted client value from $r->connection->aborted, so
  the buffer output data would not be flushed to the client, and 
  the HTML page would return to the browser empty.  This would be under
  normal file upload use.  One work-around was to make sure to initialize
  the $Request object before $Response->IsClientConnected is called,
  then $r->connection->aborted returns the right value.
  
  This problem was probably introduced with IsClientConnected() code changes
  starting in the 2.25 release.

=item $VERSION = 2.27; $DATE="10/31/2001";

 + Wrapped call to $r->connection->fileno in eval {} so to 
   preserve backwards compatibility with older mod_perl versions
   that do not have this method defined.  Thanks to Helmut Zeilinger
   for catching this.

 + removed ./dev directory from distribution, useless clutter

 + Removed dependency on HTTP::Date by taking code into
   Apache::ASP as Apache::ASP::Date.  This relieves
   the dependency of Apache::ASP on libwww LWP libraries.
   If you were using HTTP::Date functions before without loading
   "use HTTP::Date;" on your own, you will have to do this now.

 + Streamlined code execution.  Especially worked on 
   $Response->IsClientConnected which gets called during
   a normal request execution, and got rid of IO::Select
   dependency. Some function style calls instead of OO style 
   calls where private functions were being invokes that one 
   would not need to override.

 - Fixed possible bug when flushing a data buffer where there
   is just a '0' in it.

 + Updated docs to note that StateCache config was deprecated
   as of 2.23.  Removed remaining code that referenced the config.

 + Removed references to unused OrderCollections code.

 - Better Cache meta key, lower chance of collision with 
   unrelated data since its using the full MD5 keyspace now

 + Optimized some debugging statements that resulted 
   from recent development.

 + Tie::TextDir .04 and above is supported for StateDB
   and CacheDB settings with MLDBM::Sync .21. This is good for 
   CacheDB where output is larger and there are not many 
   versions to cache, like for XSLTCache, where the site is 
   mostly static.

 + Better RESOURCES section to web site, especially with adding
   some links to past Apache::ASP articles & presentations.

=item $VERSION = 2.25; $DATE="10/11/2001";

 + Improved ./site/apps/search application, for better
   search results at Apache::ASP site.  Also, reengineered
   application better, with more perl code moved to global.asa.
   Make use of MLDBM::Sync::SDBM_File, where search database
   before was engineering around SDBM_File's shortcomings.

 - Fix for SessionSerialize config, which broke in 2.23
   Also, added t/session_serialize.t to test suite to catch
   this problem in the future.

=item $VERSION = 2.23; $DATE="10/11/2001";

 +Make sure a couple other small standard modules get loaded
  upon "PerlModule Apache::ASP", like Time::HiRes, Class::Struct,
  and MLDBM::Serializer::Data::Dumper.  If not available
  these modules won't cause errors, but will promote child httpd
  RAM sharing if they are.

 -XMLSubs args parsing fix so an arg like z-index
  does not error under UseStrict.  This is OK now:

   <my:layer z-index=3 top=0 left=0> HTML </my:layer>

 -Only remove outermost <SCRIPT> tags from global.asa
  for IIS/PerlScript compatibility.  Used to remove
  all <SCRIPT> tags, which hurt when some subs in globa.asa
  would be printing some JavaScript.

 +$Response->{IsClientConnected} now updated correctly 
  before global.asa Script_OnStart.  $Response->IsClientConnect()
  can be used for accurate accounting, while 
  $Response->{IsClientConnected} only gets updated
  after $Response->Flush().  Added test cases to response.t

 +$Server->HTMLEncode(\$data) API extension, now can take
  scalar ref, which can give a 5% improvement in benchmarks
  for data 100K in size.

 -Access to $Application is locked when Application_OnEnd & 
  Application_OnStart is called, creating a critical section
  for use of $Application

 ++MLDBM::Sync used now for core DBM support in Apache::ASP::State.
  This drastically simplifies/stabilizes the code in there
  and will make it easier for future SQL database plugins.

 +New API for accessing ASP object information in non content
  handler phases:

    use Apache::ASP;
    sub My::Auth::handler {
      my $r = shift;
      my $ASP = Apache::ASP->new($r) 
      my $Session = $ASP->Session;
    }

  In the above example, $Session would be the same $Session
  object created later while running the ASP script for this
  same request.  

  Added t/asp_object.t test for this.  Fixed global.asa to only 
  init StateDir when application.asp starts which is the first 
  test script to run.

 -Fixed on Win32 to make Apache::ASP->new($r) able to create
  multiple master ASP objects per request.  Was not reentrant 
  safe before, particularly with state locking for dbms like 
  $Application & $Session.  

 ++Output caching for includes, built on same layer ( extended )
  as XSLTCache, test suite at t/cache.t.  Enabled with special 
  arguments to 

    $Response->Include(\%args, @include_args)
    $Response->TrapInclude(\%args, @include_args)
    $Server->Execute(\%args, @include_args)

  where %args = (
    File => 'file.inc',
    Cache => 1, # to activate cache layer
    Expires => 3600, # to expire in one hour
    LastModified => time() - 600, # to expire if cached before 10 minutes ago
    Key => $Request->Form, # to cache based on checksum of serialized form data,
    Clear => 1, # to not allow fetch from cache this time, will always execute include
  );

  Like the XSLTCache, it uses MLDBM::Sync::SDBM_File
  by default, but can use DB_File or GDBM_File if
  CacheDB is set to these.

  See t/cache.t for API support until this is documented.

 +CacheSize now supports units of M, K, B like 

   CacheSize 10M
   CacheSize 10240K
   CacheSize 10000000B
   CacheSize 10000000

 -Better handling of $Session->Abandon() so multiple
  request to the same session while its being destroyed
  will have the right effect.

 +Optimized XMLSubs parsing.  Scripts with lots lof XMLSubs 
  now parse faster for the first time.  One test script with 
  almost 200 such tags went from a parse time of around 3 seconds
  to .7 seconds after optimizations.

 +Updated performance tuning docs, particularly for using
  Apache::ASP->Loader()

 +$Server->URL($url, \%params) now handles array refs
  in the params values like
    $Server->URL($url, { key => [ qw( value1 value2 ) ] })

  This is so that query string data found in 
  $Request->QueryString that gets parsed into this form
  from a string like: ?key=value&key=value2 would be 
  able to be reused passed back to $Server->URL to 
  create self referencing URLs more easily.

 -Bug fix where XMLSubs like <s:td /> now works on perl 
  5.005xx, thanks to Philip Mak for reporting & fix.

 +When searching for included files, will now join
  the absolute path of the directory of the script
  with the name of the file if its a relative file
  name like ./header.inc.  Before, would just look
  for something like ././header.inc by using '.'
  as the first directory to look for includes in.

  The result of this is that scripts in two directories
  configured with the same Global setting should be able
  to have separate local header.inc files without causing
  a cached namespace collision.

 +$Server->Config() call will return a hash ref 
  to all the config setting for that request, like
  Apache->dir_config would.

 -StatINC setting with Apache::ASP->Loader() works again.
  This makes StatINC & StatINCMatch settings viable 
  for production & development use when the system has
  very many modules.

 -Cookieless session support with configs like SessionQueryParse
  and SessionQuery now work for URLs with frags in them
  like http://localhost?arg=value#frag

 +@rv = $Response->Include() now works where there are
  multiple return values from an include like:
  <% return(1,2); %>

=item $VERSION = 2.21; $DATE="8/5/2001";

 +Documented RequestParams config in CONFIG misc section.

 +Documented new XSLT caching directives.

 +Updated ./site/eg/.htaccess XSLT example config
  to use XSLTCache setting.

 +New FAQ section on why perl variables are sticky globals,
  suggested by Mark Seger.

 -push Global directory onto @INC during ASP script execution
  Protect contents of original @INC with local.  This makes
  things compatible with .09 Apache::ASP where we always had
  Global in @INC.  Fixed needed by Henrik Tougaard

 - ; is a valid separator like & for QueryString Parameters
  Fixed wanted by Anders

 -XSMLSubsMatch doc fix in CONFIG section

 +Reduces number of Session groups to 16 from 32, so 
  session manager for small user sets will be that much faster.

 +optimizations for internal database, $Application, and $Session
  creation.

 +XSLTCache must be set for XSLT caching to begin using CacheDir

 +CacheDB like StateDB bug sets dbm format for caching, which
  defaults to MLDBM::Sync::SDBM_File, which works well for caching
  output sizes < 50K

 +CacheDir config for XSLT caching ... defaults to StateDir

 +CacheSize in bytes determines whether the caches in CacheDir
  are deleted at the end of the request.  A cache will be 
  reset in this way back to 0 bytes. Defaults to 10000000 bytes
  or about 10M.

 +Caching infrastructure work that is being used in XSLT
  can be leveraged later for output caching of includes,
  or arbitrary user caching.

 -t/server_mail.t test now uses valid email for testing
  purposes ... doesn't actually send a mail, but for SMTP
  runtime validation purposes it should be OK.

 +fixed where POST data was read from under MOD_PERL,
  harmless bug this was that just generated the wrong
  system debugging message.

=item $VERSION = 2.19; $DATE="7/10/2001";

 +update docs in various parts

 +added ./make_httpd/build_httpds.sh scripts for quick builds
  of apache + mod_perl + mod_ssl

 ++plain CGI mode available for ASP execution.  
  cgi/asp script can now be used to execute ASP 
  scripts in CGI mode.  See CGI perldoc section for more info.
  The examples in ./site/eg have been set up to run
  in cgi mode if desired.  Configuration in CGI section
  only tested for Apache on Linux.

 -Fixed some faulty or out of date docs in XML/XSLT section.

 +added t/server_mail.t test for $Server->Mail(), requires
  Net::SMTP to be configured properly to succeed.

 +Net::SMTP debugging not enabled by Debug 1,2,3 configs,
  not only when system debugging is set with Debug -1,-2,-3
  However, a Debug param passed to $Server->Mail() will 
  sucessfully override the Debug -1,-2,-3 setting even
  when its Debug => 0

 -Check for undef values during stats for inline includes
  so we don't trigger unintialized warnings

 +Documented ';' may separate many directories in the IncludesDir
  setting for creating a more flexible includes search path.

=item $VERSION = 2.17; $DATE="6/17/2001";

 +Added ASP perl mmm-mode subclass and configuration
  in editors/mmm-asp-perl.el file for better emacs support.
  Updated SYNTAX/Editors documentation.

 +Better debugging error message for Debug 2 or 3 settings 
  for global.asa errors.  Limit debug output for lines
  preceding rendered script.

 -In old inline include mode, there should no longer
  be the error "need id for includes" when using
  $Response->Include() ... if DynamicIncludes were
  enabled, this problem would not have likely occured
  anyway.  DynamicIncludes are preferrable to use so
  that compiled includes can be shared between scripts.
  This bug was likely introduced in version 2.11.

 -Removed logging from $Response->BinaryWrite() in regular
  debug mode 1 or 2.  Logging still enabled in system Debug mode, -1 or -2

 -Removed other extra system debugging call that is really not
  necessary.

=item $VERSION = 2.15; $DATE="06/12/2001";

 -Fix for running under perl 5.6.1 by removing parser optimization
  introduced in 2.11.

 -Now file upload forms, forms with ENCTYPE="multipart/form-data"
  can have multiple check boxes and select items marked for 
  @params = $Request->Form('param_name') functionality.  This 
  will be demonstrated via the ./site/eg/file_upload.asp example.

=item $VERSION = 2.11; $DATE="05/29/2001";

 +Parser optimization from Dariusz Pietrzak

 -work around for global destruction error message for perl 5.6
  during install

 +$Response->{IsClientConnected} now will be set
  correctly with ! $r->connection->aborted after each
  $Response->Flush()

 +New XSLTParser config which can be set to XML::XSLT or
  XML::Sablotron.  XML::Sablotron renders 10 times faster, 
  but differently.  XML::XSLT is pure perl, so has wider
  platform support than XML::Sablotron.  This config affects
  both the XSLT config and the $Server->XSLT() method.

 +New $Server->XSLT(\$xsl_data, \$xml_data) API which 
  allows runtime XSLT on components instead of having to process
  the entire ASP output as XSLT.  

 -XSLT support for XML::XSL 0.32.  Things broke after .24.

 -XSLTCacheSize config no longer supported.  Was a bad 
  Tie::Cache implementation.  Should be file based cache
  to greatly increases cache hit ratio.

 ++$Response->Include(), $Response->TrapInclude(),
  and $Server->Execute() will all take a scalar ref
  or \'asdfdsafa' type code as their first argument to execute 
  a raw script instead of a script file name.  At this time, 
  compilation of such a script, will not be cached.  It is 
  compiled/executed as an anonymous subroutine and will be freed
  when it goes out of scope.

 + -p argument to cgi/asp script to set GlobalPackage
  config for static site builds

 -pod commenting fix where windows clients are used for 
  ASP script generation.

 +Some nice performance enhancements, thank to submissions from
  Ime Smits.  Added some 1-2% per request execution speed.

 +Added StateDB MLDBM::Sync::SDBM_File support for faster
  $Session + $Application than DB_File, yet still overcomes
  SDBM_File's 1024 bytes value limitation.  Documented in 
  StateDB config, and added Makefile.PL entry.

 +Removed deprecated MD5 use and replace with Digest::MD5 calls

 +PerlSetVar InodeNames 1 config which will compile scripts hashed by 
  their device & inode identifiers, from a stat($file)[0,1] call.
  This allows for script directories, the Global directory,
  and IncludesDir directories to be symlinked to without
  recompiling identical scripts.  Likely only works on Unix
  systems.  Thanks to Ime Smits for this one.

 +Streamlined code internally so that includes & scripts were
  compiled by same code.  This is a baby step toward fusing
  include & script code compilation models, leading to being
  able to compile bits of scripts on the fly as ASP subs, 
  and being able to garbage collect ASP code subroutines.

 -removed @_ = () in script compilation which would trigger warnings 
  under PerlWarn being set, thanks for Carl Lipo for reporting this.

 -StatINC/StatINCMatch fix for not undeffing compiled includes
  and pages in the GlobalPackage namespace

 -Create new HTML::FillInForm object for each FormFill
  done, to avoid potential bug with multiple forms filled
  by same object.  Thanks to Jim Pavlick for the tip.

 +Added PREREQ_PM to Makefile.PL, so CPAN installation will
  pick up the necessary modules correctly, without having
  to use Bundle::Apache::ASP, thanks to Michael Davis. 

 + > mode for opening lock files, not >>, since its faster

 +$Response->Flush() fixed, by giving $| = 1 perl hint
  to $r->print() and the rest of the perl sub.

 +$Response->{Cookies}{cookie_name}{Expires} = -86400 * 300;
  works so negative relative time may be used to expire cookies.

 +Count() + Key() Collection class API implementations

 +Added editors/aasp.vim VIM syntax file for Apache::ASP,
  courtesy of Jon Topper.

 ++Better line numbering with #line perl pragma.  Especially
  helps with inline includes.  Lots of work here, & integrated
  with Debug 2 runtime pretty print debugging.

 +$Response->{Debug} member toggles on/off whether 
  $Response->Debug() is active, overriding the Debug setting
  for this purpose.  Documented.

 -When Filter is on, Content-Length won't be set and compression
  won't be used.  These things would not work with a filtering
  handler after Apache::ASP

=item $VERSION = 2.09; $DATE="01/30/2001";

 +Examples in ./site/eg are now UseStrict friendly.  
  Also fixed up ./site/eg/ssi_filter.ssi example.

 +Auto purge of old stale session group directories, increasing 
  session manager performance when using Sessions when migrating
  to Apache::ASP 2.09+ from older versions.

 +SessionQueryParse now works for all $Response->{ContentType}
  starting with 'text' ... before just worked with text/html,
  now other text formats like wml will work too. 

 +32 groups instead of 64, better inactive site session group purging.

 +Default session-id length back up to 32 hex bytes.
  Better security vs. performance, security more important,
  especially when performance difference was very little.

 +PerlSetVar RequestParams 1 creates $Request->Params
  object with combined contents of $Request->QueryString
  and $Request->Form

 ++FormFill feature via HTML::FillInForm.  Activate with
  $Response->{FormFill} = 1 or PerlSetVar FormFill 1
  See site/eg/formfill.asp for example.

 ++XMLSubs tags of the same name may be embedded in each other
  recursively now.

 +No umask() use on Win32 as it seems unclear what it would do

 +simpler Apache::ASP::State file handle mode of >> when opening 
  lock file.  saves doing a -e $file test.

 +AuthServerVariables config to init $Request->ServerVariables
  with basic auth data as documented.  This used to be default
  behavior, but triggers "need AuthName" warnings from recent
  versions of Apache when AuthName is not set.

 -Renamed Apache::ASP::Loader class to Apache::ASP::Load
  as it collided with the Apache::ASP->Loader() function
  namespace.  Class used internally by Apache::ASP->Loader()
  so no public API changed here.

 +-Read of POST input for $Request->BinaryRead() even
   if its not from a form.  Only set up $Request->Form
   if this is from a form POST.

 +faster POST/GET param parsing

=item $VERSION = 2.07; $DATE="11/26/2000";

 -+-+ Session Manager
  empty state group directories are not removed, thus alleviating
  one potential race condition.  This impacted performance
  on idle sites severely as there were now 256 directories
  to check, so made many performance enhancements to the 
  session manager.  The session manager is built to handle
  up to 20,000 client sessions over a 20 minute period.  It
  will slow the system down as it approaches this capacity.

  One such enhancement was session-ids now being 11 bytes long 
  so that its .lock file is only 16 characters in length.  
  Supposedly some file systems lookup files 16 characters or 
  less in a fast hashed lookup.  This new session-id has
  4.4 x 10^12 possible values.  I try to keep this space as
  large as possible to prevent a brute force attack.

  Another enhancement was to limit the group directories
  to 64 by only allowing the session-id prefix to be [0-3][0-f]
  instead of [0-f][0-f], checking 64 empty directories on an
  idle site takes little time for the session manager, compared
  to 256 which felt significant from the client end, especially
  on Win32 where requests are serialized.  

  If upgrading to this version, you would do well to delete
  empty StateDir group directories while your site is idle.
  Upgrading during an idle time will have a similar effect,
  as old Apache::ASP versions would delete empty directories.

 -$Application->GetSession($session_id) now creates
  an session object that only lasts until the next
  invocation of $Application->GetSession().  This is 
  to avoid opening too many file handles at once,
  where each session requires opening a lock file.

 +added experimental support for Apache::Filter 1.013 
  filter_register call

 +make test cases for $Response->Include() and 
  $Response->TrapInclude()

 +Documented CollectionItem config.

 +New $Request->QueryString('multiple args')->Count()
  interface implemented for CollectionItem config.
  Also $Request->QueryString('multiple args')->Item(1) method.
  Note ASP collections start counting at 1.

 --fixed race condition, where multiple processes might 
  try creating the same state directory at the same time, with
  one winning, and one generating an error.  Now, web process
  will recheck for directory existence and error if 
  it doesn't. 

 -global.asa compilation will be cached correctly, not
  sure when this broke.  It was getting reloaded every request.

 -StateAllWrite config, when set creates state files
  with a+rw or 0666 permissions, and state directories
  with a+rwx or 0777 permissions.  This allows web servers
  running as different users on the same machine to share a 
  common StateDir config.  Also StateGroupWrite config
  with perms 0770 and 0660 respectively.

 -Apache::ASP->Loader() now won't follow links to 
  directories when searching for scripts to load.

 +New RegisterIncludes config which is on by default only
  when using Apache::ASP->Loader(), for compiling includes
  when precompiling scripts.

 +Apache::ASP::CompileInclude path optimized, which underlies
  $Response->Include()

 +$Request->QueryString->('foo')->Item() syntax enabled
  with CollectionItem config setting.  Default syntax
  supported is $Request->QueryString('foo') which is
  in compatible.  Other syntax like $Request->{Form}{foo}
  and $Request->Form->Item('foo') will work in either case.

 +New fix suggested for missing Apache reference in 
  Apache::ASP handler startup for RedHat RPMs.  Added
  to error message.

 --Backup flock() unlocking try for QNX will not corrupt the 
  normal flock() LOCK_UN usage, after trying to unlock a file
  that doesn't exist.  This bug was uncovered from the below 
  group deletion race condition that existed. 

 -Session garbage collection will not delete new group
  directories that have just been created but are empty.
  There was a race condition where a new group directory would
  be created, but then deleted by a garbage collector before
  it could be initialized correctly with new state files.

 +Better random session-id checksums for $Session creation.
  per process srand() initialization, because srand() 
  may be called once prefork and never called again.
  Call without arguments to rely on perl's decent rand
  seeding.  Then when calling rand() in Secret() we have
  enough random data, that even if someone else calls srand()
  to something fixed, should not mess things up terribly since
  we checksum things like $$ & time, as well as perl memory
  references.

 +XMLSubs installation make test.

 -Fix for multiline arguments for XMLSubs

=item $VERSION = 2.03; $DATE="08/01/2000";

 +License change to GPL.  See LICENSE section.

 +Setup of www.apache-asp.org site, finally!

 -get rid of Apache::ASP->Loader() warning message for perl 5.6.0

=item $VERSION = 2.01; $DATE="07/22/2000";

 +$data_ref = $Response->TrapInclude('file.inc') API
  extension which allows for easy post processing of
  data from includes

 +./site/eg/source.inc syntax highlighting improvements

 +XMLSubsMatch compile time parsing performance improvement

=item $VERSION = 2.00; $DATE="07/15/2000";

 -UniquePackages config works again, broke a couple versions back

 +better error handling for methods called on $Application
  that don't exist, hard to debug before

=item $VERSION = 1.95; $DATE="07/10/2000";

 !!!!! EXAMPLES SECURITY BUG FOUND & FIXED !!!!!

 --FIXED: distribution example ./site/eg/source.asp now parses 
  out special characters of the open() call when reading local 
  files.

  This bug would allow a malicious user possible writing
  of files in the same directory as the source.asp script.  This
  writing exploit would only have effect if the web server user
  has write permission on those files.

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

 -$0 now set to transferred file, when using $Server->Transfer

 -Fix for XMLSubsMatch parsing on cases with 2 or more args passed
  to tag sub that was standalone like 
    <Apps:header type="header" title="Moo" foo="moo" />

=item $VERSION = 1.93; $DATE="07/03/2000";

 -sub second timing with Time::HiRes was adding <!-- -->
  comments by HTML by default, which would possibly
  break specific programs looking for precise HTML output.
  Now this behavior must be explicitly turned on with
  the TimeHiRes config setting.

  These comments will only appear in HTML only if 
  Debug is enabled as well.

  Timed log entries will only occur if 
  system debugging is enabled, with Debug -1 or -2

=item $VERSION = 1.91; $DATE="07/02/2000";

 +Documented XMLSubsMatch & XSLT* configuration
  settings in CONFIG section.

 +XSLT XSL template is now first executed as an 
  ASP script just like the XML scripts.  This is 
  just one step away now from implementing XSP logic.

 +$Server->Execute and $Server->Transfer API extensions
  implemented.  Execute is the same as $Request->Include()
  and $Server->Transfer is like an apache internal redirect
  but keeps the current ASP objects for the next script.

  Added examples, transfer.htm, and modified dynamic_includes.htm.

 +Better compile time error debugging with Debug 2 or -2.
  Will hilite/link the buggy line for global.asa errors, 
  include errors, and XML/XSLT errors just like with 
  ASP scripts before.

 +Nice source hiliting when viewing source for the example
  scripts.

 +Runtime string writing optimization for static HTML going
  through $Response.

 +New version numbering just like everyone else.  Starting at 1.91
  since I seem to be off by a factor of 10, last release would have
  been 1.9.

=item $VERSION = 0.19; $DATE="NOT RELEASED";

 +XMLSubsMatch and XSLT* settings documented in 
  the XML/XSLT section of the site/README.

 -XMLSubsMatch will strip parens in a pattern match
  so it does not interfere with internal matching use.

 +XSLT integration allowing XML to be rendered by XSLT
  on the fly.  XSLT specifies XSL file to transform XML.
  XSLTMatch is a regexp that matches XML file names, like \.xml$,
  which will be transformed by XSLT setting, default .*
  
  XSLTCacheSize when specified uses Tie::Cache to cached XML DOMs 
  internally and cache XSLT transformations output per XML/XSL 
  combination.  XML DOM objects can take a lot of RAM, so use
  this setting judiciously like setting to 100.  Definitely 
  experiment with this value.

 +More client info in the error mail feature, including
  client IP, form data, query string, and HTTP_* client headers

 +With Time::HiRes loaded, and Debug set to non 0, 
  will add a <!-- Apache::ASP served request in xx.xx seconds -->
  to text/html output, similar to Cocoon, per user request  
  Will also add this to the system debug error log output
  when Debug is < 0

 -bug fix on object initialization optimization earlier
  in this release, that was introduced for faster event
  handler execution.

 +Apache::ASP::Parse() takes a file name, scalar, or
  scalar ref for arguments of data to parse for greater
  integration ability with other applications.

 +PodComments optimization, small speed increase at
  compilation time.

 +String optimization on internal rendering that avoids 
  unnecessary copying of static html, by using refs.  Should 
  make a small difference on sites with large amounts of 
  static html.

 +CompressGzip setting which, when Compress::Zlib is installed,
  will compress text/html automatically going out to the web
  browser if the client supports gzip encoding.

 ++Script_OnFlush event handler, and auxiliary work optimizing
  asp events in general.  $Response->{BinaryRef} created which
  is a reference to outgoing output, which can be used 
  to modify the data at runtime before it goes out to the client. 

 +Some code optimizations that boost speed from 22 to 24 
  hits per second when using Sessions without $Application,
  on a simple hello world benchmark on a WinNT PII300.

 ++Better SessionManagement, more aware of server farms that 
  don't have reliable NFS locking.  The key here is to have only
  one process on one server in charge of session garbage collection
  at any one time, and try to create this situation with a snazzy
  CleanupMaster routine.  This is done by having a process register
  itself in the internal database with a server key created at
  apache start time.  If this key gets stale, another process can 
  become the master, and this period will not exceed the period
  SessionTimeout / StateManager.

  ** Work on session manager sponsored by LRN, http://www.lrn.com.  **
  ** This work was used to deploy a server farm in production with  **
  ** NFS mounted StateDir. Thanks to Craig Samuel for his belief in **
  ** open source. :)                                                **

  Future work for server farm capabilities might include breaking
  up the internal database into one of 256 internal databases 
  hashed by the first 2 chars of the session id.  Also on the plate
  is Apache::Session like abilities with locking and/or data storage
  occuring in a SQL database.  The first dbs to be done will include
  MySQL & Oracle.

 +Better session security which will create a new session id for an 
  incoming session id that does not match one already seen.  This will
  help for those with Search engines that have bookmarked
  pages with the session ids in the query strings.  This breaks away
  from standard ASP session id implementation which will automatically
  use the session id presented by the browser, now a new session id will
  be returned if the presented one is invalid or expired.

 -$Application->GetSession will only return a session if
  one already existed.  It would create one before by default.

 +Script_OnFlush global.asa event handler, and $Response->{BinaryRef}
  member which is a scalar reference to the content about to be flushed.
  See ./site/eg/global.asa for example usage, used in this case to
  insert font tags on the fly into the output.

 +Highlighting and linking of line error when Debug is set to 2 or -2.

 --removed fork() call from flock() backup routine? How did 
   that get in there?  Oh right, testing on Win32. :(
   Very painful lesson this one, sorry to whom it may concern.

 +$Application->SessionCount support turned off by default
  must enable with SessionCount config option.  This feature
  puts an unnecessary load on busy sites, so not default 
  behavior now.  

 ++XMLSubsMatch setting that allows the developer to 
  create custom tags XML style that execute perl subroutines.
  See ./site/eg/xml_subs.asp

 +MailFrom config option that defaults the From: field for 
  mails sent via the Mail* configs and $Server->Mail()

 +$Server->Mail(\%mail, %smtp_args) API extension

 +MailErrorsTo & MailAlertTo now can take comma
  separated email addresses for multiple recipients.

 -tracking of subroutines defined in scripts and includes so 
  StatINC won't undefine them when reloading the GlobalPackage, 
  and so an warning will be logged when another script redefines 
  the same subroutine name, which has been the bane of at least
  a few developers.

 -Loader() will now recompile dynamic includes that 
  have changed, even if main including script has not.
  This is useful if you are using Loader() in a 
  PerlRestartHandler, for reloading scripts when
  gracefully restarting apache.

 -Apache::ASP used to always set the status to 200 by 
  default explicitly with $r->status().  This would be 
  a problem if a script was being used to as a 404 
  ErrorDocument, because it would always return a 200 error
  code, which is just wrong.  $Response->{Status} is now 
  undefined by default and will only be used if set by 
  the developer.  

  Note that by default a script will still return a 200 status, 
  but $Response->{Status} may be used to override this behavior.

 +$Server->Config($setting) API extension that allows developer
  to access config settings like Global, StateDir, etc., and is a 
  wrapper around Apache->dir_config($setting)

 +Loader() will log the number of scripts
  recompiled and the number of scripts checked, instead
  of just the number of scripts recompiled, which is
  misleading as it reports 0 for child httpds after
  a parent fork that used Loader() upon startup.  	

 -Apache::ASP->Loader() would have a bad error if it didn't load 
  any scripts when given a directory, prints "loaded 0 scripts" now

=item $VERSION = 0.18; $DATE="02/03/2000";

 +Documented SessionQuery* & $Server->URL() and 
  cleaned up formatting some, as well as redoing
  some of the sections ordering for better readability.
  Document the cookieless session functionality more
  in a new SESSIONS section.  Also documented new 
  FileUpload configs and $Request->FileUpload collection.
  Documented StatScripts.

 +StatScripts setting which if set to 0 will not reload
  includes, global.asa, or scripts when changed.

 +FileUpload file handles cleanup at garbage collection
  time so developer does not have to worry about lazy coding
  and undeffing filehandles used in code.  Also set 
  uploaded filehandles to binmode automatically on Win32 
  platforms, saving the developer yet more typing.

 +FileUploadTemp setting, default 0, if set will leave
  a temp file on disk during the request, which may be 
  helpful for processing by other programs, but is also
  a security risk in that others could potentially read 
  this file while the script is running. 

  The path to the temp file will be available at
  $Request->{FileUpload}{$form_field}{TempFile}.
  The regular use of file uploads remains the same
  with the <$filehandle> to the upload at 
  $Request->{Form}{$form_field}.

 +FileUploadMax setting, default 0, currently an 
  alias for $CGI::POST_MAX, which determines the 
  max size for a file upload in bytes.  

 +SessionQueryParse only auto parses session-ids
  into links when a session-id COOKIE is NOT found.
  This feature is only enabled then when a user has
  disabled cookies, so the runtime penalty of this
  feature won't drag down the whole site, since most
  users will have cookies turned on.   

 -StatINC & StatINCMatch will not undef Fnctl.pm flock 
  functions constants like O_RDWR, because the code references
  are not well trackable.  This would result in sporadic 500 server
  errors when a changed module was reloaded that imported O_* flock 
  functions from Fnctl.

 +SessionQueryParse & SessionQueryParseMatch
  settings that enable auto parsing session ids into 
  URLs for cookieless sessions.  Will pick up URLs in 
  <a href>, <area href>, <form action>, <frame src>,
  <iframe src>, <img src>, <input src>, <link href>
  $Response->Redirect($URL) and the first URL in 
  script tags like <script>*.location.href=$URL</script>

  These settings require that buffering be enabled, as
  Apache::ASP will parse through the buffer to parse the URLs.

  With SessionQueryParse on, it will just parse non-absolute
  URLs, but with SessionQueryParseMatch set to some server
  url regexp, like ^http://localhost , will also parse
  in the session id for URLs that match that.

  When testing, the performance hit from this parsing
  a script dropped from 12.5 hits/sec on my WinNT box
  to 11.7 hits per second for 1K of buffered output.
  The difference is .007 of my PII300's processing power
  per second.

  For 10K of output then, my guess is that this speed
  of script, would be slowed to 6.8 hits per second.
  This kind of performance hit would also slow a
  script running at 40 hits per second on a UNIX box
  to 31 hits/sec for 1K, and to 11 hits/sec for 10K parsed.

  Your mileage may vary and you will have to test the difference
  yourself.  Get yourself a valid URL with a session-id in
  it, and run it through ab, or Socrates, with SessionQuery
  turned on, and then with SessionQueryParse set to see 
  the difference.  SessionQuery just enables of session id
  setting from the query string but will not auto parse urls.

 -If buffering, Content-Length will again be set.
  It broke, probably while I was tuning in the past 
  couple versions.

 +UseStrict setting compiles all scripts including
  global.asa with "use strict" turned on for catching
  more coding errors.  With this setting enabled,
  use strict errors die during compilation forcing
  Apache::ASP to try to recompile the script until
  successful.

 -Object use in includes like $Response->Write() 
  no longer error with "use strict" programming.  

 +SessionQuery config setting with $Server->URL($url, { %params } ) 
  alpha API extensions to enable cookieless sessions.

 +Debugging not longer produces internal debugging
  by default.  Set to -1,-2 for internal debugging
  for Debug settings 1 & 2.

 +Both StateSerializer & StateDB can be changed 
  without affecting a live web site, by storing 
  the configurations for $Application & $Session 
  in an internal database, so that if $Session was
  created with SDBM_File for the StateDB (default),
  it will keep this StateDB setting until it ends.

 +StateSerializer config setting.  Default Data::Dumper,
  can also be set to Storable.  Controls how data is
  serialized before writing to $Application & $Session.

 +Beefed up the make test suite.

 +Improved the locking, streamlining a bit of the 
  $Application / $Session setup process.  Bench is up to 
  22 from 21 hits / sec on dev NT box.

 +Cut more fat for faster startup, now on my dev box 
  I get 44 hits per sec Apache::ASP vs. 48 Embperl 
  vs. 52 CGI via Apache::Registry for the HelloWorld Scripts.

 -Improved linking for the online site documentation, 
  where a few links before were bad.

=item $VERSION = 0.17; $DATE="11/15/99";

 ++20%+ faster startup script execution, as measured by the 
  HelloWorld bench.  I cut a lot of the fat out of 
  the code, and is now at least 20% faster on startup 
  both with and without state.

  On my dev (NT, apache 1.3.6+mod_perl) machine, I now get:

	42 hits per sec on Apache::ASP HelloWorld bench
	46 hits per sec on Embperl (1.2b10) and
	51 hits per sec for CGI Apache::Registry scripts  

  Before Apache::ASP was clocking some 31 hits per sec.
  Apache::ASP also went from 75 to 102 hits per second 
  on Solaris.

 +PerlTaintCheck On friendly.  This is mod_perl's way 
  of providing -T taint checking.  When Apache::ASP
  is used with state objects like $Session or $Application,
  MLDBM must also be made taint friendly with:

    $MLDBM::RemoveTaint = 1;

  which could be put in the global.asa.  Documented.

 +Added $Response->ErrorDocument($error_code, $uri_or_string) 
  API extension which allows for setting of Apache's error
  document at runtime.  This is really just a wrapper 
  for Apache->custom_response() renamed so it syncs with
  the Apache ErrorDocument config setting.  Updated
  documentation, and added error_document.htm example.

 =OrderCollections setting was added, but then REMOVED
  because it was not going to be used.  It bound 
  $Request->* collections/hashes to Tie::IxHash, so that data
  in those collections would be read in the order the 
  browser sent it, when eaching through or with keys.

 -global.asa will be reloaded when changed.  This broke
  when I optimized the modification times with (stat($file))[9]
  rather than "use File::stat; stat($file)->mtime"

 -Make Apache::ASP->Loader() PerlRestartHandler safe,
  had some unstrict code that was doing the wrong thing.

 -IncludesDir config now works with DynamicIncludes.

 +DebugBufferLength feature added, giving control to 
  how much buffered output gets shown when debugging errors.

 ++Tuning of $Response->Write(), which processes all
  static html internally, to be almost 50% faster for
  its typical use, when BufferingOn is enabled, and 
  CgiHeaders are disabled, both being defaults.

  This can show significant speed improvements for tight
  loops that render ASP output.

 +Auto linking of ./site/eg/ text to example scripts
  at web site.

 +$Application->GetSession($session_id) API extension, useful
  for managing active user sessions when storing session ids
  in $Application.  Documented.

 -disable use of flock() on Win95/98 where it is unimplemented

 -@array context of $Request->Form('name') returns
  undef when value for 'name' is undefined.  Put extra
  logic in there to make sure this happens. 

=item $VERSION = 0.16; $DATE="09/22/99";

 -$Response->{Buffer} and PerlSetVar BufferingOn
  configs now work when set to 0, to unbuffer output,
  and send it out to the web client as the script generates it.

  Buffering is enabled by default, as it is faster, and
  allows a script to error cleanly in the middle of execution.  

 +more bullet proof loading of Apache::Symbol, changed the 
  way Apache::ASP loads modules in general.  It used to 
  check for the module to load every time, if it hadn't loaded
  successfully before, but now it just tries once per httpd,
  so the web server will have to be restarted to see new installed
  modules.  This is just for modules that Apache::ASP relies on.

  Old modules that are changed or updated with an installation
  are still reloaded with the StatINC settings if so configured. 

 +ASP web site wraps <font face="courier new"> around <pre>
  tags now to override the other font used for the text
  areas.  The spacing was all weird in Netscape before
  for <pre> sections.

 -Fixed Content-Length calculation when using the Clean
  option, so that the length is calculated after the HTML
  is clean, not before.  This would cause a browser to 
  hang sometimes.

 +Added IncludesDir config option that if set will also be
  used to check for includes, so that includes may easily be
  shared between applications.  By default only Global and 
  the directory the script is in are checked for includes.

  Also added IncludesDir as a possible configuration option
  for Apache::ASP->Loader()

 -Re-enabled the Application_OnStart & OnEnd events, after
  breaking them when implementing the AllowApplicationState
  config setting.

 +Better pre-fork caching ... StatINC & StatINCMatch are now 
  args for Apache::ASP->Loader(), so StatINC symbols loading
  may be done pre-fork and shared between httpds.  This lowers
  the child httpd init cost of StatINC.  Documented.

 +Made Apache::ASP Basic Authorization friendly so authentication
  can be handled by ASP scripts.  If AuthName and AuthType Apache
  config directives are set, and a $Response->{Status} is set to 
  401, a user will be prompted for username/password authentication
  and the entered data will show up in ServerVariables as:
    $env = $Request->ServerVariables
    $env->{REMOTE_USER} = $env->{AUTH_USER} = username
    $env->{AUTH_PASSWD} = password
    $env->{AUTH_NAME}   = your realm
    $env->{AUTH_TYPE}   = 'Basic'

  This is the same place to find auth data as if Apache had some 
  authentication handler deal with the auth phase separately.

 -MailErrorsTo should report the right file now that generates
  the error.

=item $VERSION = 0.15; $DATE="08/24/1999";

 --State databases like $Session, $Application are 
  now tied/untied to every lock/unlock triggered by read/write 
  access.  This was necessary for correctness issues, so that 
  database file handles are flushed appropriately between writes
  in a highly concurrent multi-process environment.

  This problem raised its ugly head because under high volume, 
  a DB_File can become corrupt if not flushed correctly.  
  Unfortunately, there is no way to flush SDBM_Files & DB_Files 
  consistently other than to tie/untie the databases every access.

  DB_File may be used optionally for StateDB, but the default is
  to use SDBM_File which is much faster, but limited to 1024 byte
  key/value pairs.

  For SDBM_Files before, if there were too many concurrent 
  writes to a shared database like $Application, some of the 
  writes would not be saved because another process
  might overwrite the changes with its own.

  There is now a 10 fold performance DECREASE associated
  with reading from and writing to files like $Session 
  and $Application.  With rough benchmarks I can get about
  100 increments (++) now per second to $Session->{count}, where
  before I could get 1000 increments / second.  

  You can improve this if you have many reads / writes happening
  at the same time, by placing locking code around the group like
  
	$Session->Lock();
	$Session->{count}++;
	$Session->{count}++;
	$Session->{count}++;
	$Session->UnLock();	

  This method will reduce the number of ties to the $Session database
  from 6 to 1 for this kind of code, and will improve the performance
  dramatically.

  Also, instead of using explicit $Session locking, you can 
  create an automatic lock on $Session per script by setting
  SessionSerialize in your config to 1.  The danger here is
  if you have any long running scripts, the user will have
  to wait for it to finish before another script can be run.

  To see the number of lock/unlocks or ties/unties to each database
  during a script execution, look at the last lines of debug output
  to your error log when Debug is set to 1.  This can help you
  performance tweak access to these databases.

 +Updated documentation with new config settings and
  API extensions.

 +Added AllowApplicationState config option which allows
  you to leave $Application undefined, and will not
  execute Application_OnStart or Application_OnEnd.
  This can be a slight performance increase of 2-3% if
  you are not using $Application, but are using $Session.

 +Added $Session->Lock() / $Session->UnLock() API routines
  necessary additions since access to session is not
  serialized by default like IIS ASP.  Also prompted
  by change in locking code which retied to SDBM_File
  or DB_File each lock.  If you $Session->Lock / UnLock
  around many read/writes, you will increase performance.

 +Added StateCache config which, if set will cache
  the file handle locks for $Application and an internal 
  database used for tracking $Session info.  This caching can 
  make an ASP application perform up to 10% faster,
  at a cost of each web server process holding 2 more 
  cached file handles open, per ASP application using
  this configuration.  The data written to or read from
  these state databases is not cached, just the locking 
  file handles are held open.

 -Added in much more locking in session manager 
  and session garbage collector to help avoid collisions
  between the two.  There were definite windows that the
  two would collide in, during which bad things could 
  happen on a high volume site.

 -Fixed some warnings in DESTROY and ParseParams()

=item $VERSION = 0.14; $DATE="07/29/1999";

 -CGI & StatINC or StatINCMatch would have bad results
  at times, with StatINC deleting dynamically compiled
  CGI subroutines, that were imported into other scripts
  and modules namespaces.

  A couple tweaks, and now StatINC & CGI play nice again ;)
  StatINCMatch should be safe to use in production with CGI. 
  This affects in particular environments that use file upload, 
  since CGI is loaded automatically by Apache::ASP to handle 
  file uploads.

  This fix should also affect other seemingly random 
  times when StatINC or StatINCMatch don't seem to do 
  the right thing.

 +use of ASP objects like $Response are now "use strict"
  safe in scripts, while UniquePackages config is set.

 +Better handling of "use strict" errors in ASP scripts.
  The error is detected, and the developer is pointed to the 
  Apache error log for the exact error.  

  The script with "use strict" errors will be recompiled again.  Its seems 
  though that "use strict" will only throw its error once, so that a script 
  can be recompiled with the same errors, and work w/o any use strict
  error messaging.  

=item $VERSION = 0.12; $DATE="07/01/1999";

 -Compiles are now 10 +times faster for scripts with lots of big
  embedded perl blocks <% #perl %>

  Compiles were slow because of an old PerlScript compatibility
  parsing trick where $Request->QueryString('hi')->{item}
  would be parsed to $Request->QueryString('hi') which works.
  I think the regexp that I was using had O(n^2) characteristics
  and it took a really big perl block to 10 +seconds to parse
  to understand there was a problem :(

  I doubt anyone needed this compatibility, I don't even see
  any code that looks like this in the online PerlScript examples,
  so I've commented out this parsing trick for now.  If you 
  need me to bring back this functionality, it will be in the 
  form of a config setting.

  For information on PerlScript compatibility, see the PerlScript
  section in the ASP docs.

 -Added UniquePackages config option, that if set brings back 
  the old method of compiling each ASP script into its own
  separate package.  As of v.10, scripts are compiled by default
  into the same package, so that scripts, dynamic includes & global.asa
  can share globals.  This BROKE scripts in the same ASP Application
  that defined the same sub routines, as their subs would redefine
  each other.  

  UniquePackages has scripts compiled into separate perl packages,
  so they may define subs with the same name, w/o fear of overlap.
  Under this settings, scripts will not be able to share globals.  

 -Secure field for cookies in $Response->Cookies() must be TRUE to 
  force cookie to be secure.  Before, it just had to be defined, 
  which gave wrong behavior for Secure => 0. 

 +$Response->{IsClientConnected} set to one by default.  Will
  work out a real value when I upgrade to apache 1.3.6.  This
  value has no meaning before, as apache aborts the perl code
  when a client drops its connection in earlier versions.

 +better compile time debugging of dynamic includes, with 
  Debug 2 setting

 +"use strict" friendly handling of compiling dynamic includes
  with errors

=item $VERSION = 0.11; $DATE="06/24/1999";

 +Lots of documentation updates

 +The MailHost config option is the smtp server used for 
  relay emails for the Mail* config options.

 +MailAlertTo config option used for sending a short administrative
  alert for an internal ASP error, server code 500.  This is the 
  compliment to MailErrorsTo, but is suited for sending a to a
  small text based pager.  The email sent by MailErrorsTo would
  then be checked by the web admin for quick response & debugging
  for the incident. 

  The MailAlertPeriod config specifies the time in minutes during 
  which only one alert will be sent, which defaults to 20.

 +MailErrorsTo config options sends the results of a 500 error
  to the email address specified as if Debug were set to 2.
  If Debug 2 is set, this config will not be on, as it is
  for production use only.  Debug settings less than 2 only 
  log errors to the apache server error log.

 -StatINCMatch / StatINC can be used in production and work
  even after a server graceful restart, which is essential for 
  a production server.

 -Content-Length header is set again, if BufferingOn is set, and
  haven't $Response->Flush()'d.  This broke when I introduce
  the Script_OnEnd event handler.

 +Optimized reloading of the GlobalPackage perl module upon changes, 
  so that scripts and dynamic includes don't have to be recompiled.  
  The global.asa will still have to be though.  Since we started
  compiling all routines into a package that can be named with
  GlobalPackage, we've been undeffing compiled scripts and includes
  when the real GlobalPackage changed on disk, as we do a full sweep
  through the namespace.  Now, we skip those subs that we know to 
  be includes or scripts. 

 -Using Apache::Symbol::undef() to undefine precompiled scripts
  and includes when reloading those scripts.  Doing just an undef() 
  would sometimes result in an "active subroutine undef" error.
  This bug came out when I started thrashing the StatINC system
  for production use.

 +StatINCMatch setting created for production use reloading of
  perl modules.  StatINCMatch allows StatINC reloading of a
  subset of all the modules defined in %INC, those that match
  $module =~ /$StatINCMatch/, where module is some module name
  like Class/Struct.pm

 +Reoptimized pod comment parsing.  I slowed it down to sync
  lines numbers in the last version, but found another corner I could cut.

=item $VERSION = 0.10; $DATE="05/24/1999";

 += improvement; - = bug fix

 +Added index.html file to ./eg to help people wade through
  the examples.  This one has been long overdue.

 +Clean config option, or setting $Response->{Clean} to 1 - 9,
  uses HTML::Clean to compress text/html output of ASP scripts.
  I like the Clean 1 setting which is lightweight, stripping 
  white space for about 10% compression, at a cost of less than
  a 5% performance penalty.

 +Using pod style commenting no longer confuses the line
  numbering.  ASP script line numbers are almost exactly match
  their compiled perl version, except that normal inline includes
  (not dynamic) insert extra text which can confuse line numbering.
  If you want perl error line numbers to entirely sync with your 
  ASP scripts, I would suggest learning how to use dynamic includes,
  as opposed to inline includes.

 -Wrapped StatINC reloading of libs in an eval, and capturing
  error for Debug 2 setting.  This makes changing libs with StatINC
  on a little more friendly when there are errors. 

 -$Request->QueryString() now stores multiple values for the 
  same key, just as $Request->Form() has since v.07.  In
  wantarray() context like @vals = $Request->QueryString('dupkey'),
  @vals will store whatever values where associated with dupkey
  in the query string like (1,2) from: ?dupkey=1&dupkey=2

 +The GlobalPackage config directive may be defined
  to explicitly set the perl module that all scripts and global.asa
  are compiled into.

 -Dynamic includes may be in the Global directory, just like
  normal includes.

 +Perl script generated from asp scripts should match line
  for line, seen in errors, except when using inline (default) 
  includes, pod comments, or <% #comment %> perl comments, which 
  will throw off the line counts by adding text, removing
  text, or having an extra newline added, respectively.

 -Script_OnEnd may now send output to the browser.  Before
  $main::Response->End() was being called at the end of the
  main script preventing further output.

++All scripts are compiled as routines in a namespace uniquely
  defined by the global.asa of the ASP application.  Thus,
  scripts, includes, and global.asa routines will share
  all globals defined in the global.asa namespace.   This means
  that globals between scripts will be shared, and globals
  defined in a global.asa will be available to scripts.

  Scripts used to have their own namespace, thus globals
  were not shared between them.

 +a -o $output_dir switch on the ./cgi/asp script allows
  it to execute scripts and write their output to an output
  directory.  Useful for building static html sites, based on
  asp scripts.  An example use would be:

    asp -b -o out *.asp

  Without an output directory, script output is written to STDOUT


=item $VERSION = 0.09; $DATE="04/22/1999";

 +Updated Makefile.PL optional modules output for CGI & DB_File

 +Improved docs on $Response->Cookies() and $Request->Cookies()

 +Added PERFORMANCE doc to main README, and added sub section
  on precompiling scripts with Apache::ASP->Loader()

 +Naming of CompileIncludes switched over to DynamicIncludes 
  for greater clarity.

 +Dynamic includes can now reference ASP objects like $Session
  w/o the $main::* syntax.  These subs are no longer anonymous
  subs, and are now compiled into the namespace of the global.asa package.

 +Apache::ASP->Loader() precompiles dynamic includes too. Making this work
  required fixing some subtle bugs / dependencies in the compiling process.

 +Added Apache::ASP->Loader() similar to Apache::RegistryLoader for
  precompiling ASP scripts.  Precompile a whole site at server 
  startup with one function call.

 +Prettied the error messaging with Debug 2.

 +$Response->Debug(@args) debugging extension, which
  allows a developer to hook into the module's debugging,
  and only have @args be written to error_log when Debug is greater
  than 0.

 -Put write locking code around State writes, like $Session
  and $Application.  I thought I fixed this bug a while ago.

 -API change: converted $Session->Timeout() and $Session->SessionID() 
  methods into $Session->{Timeout} and $Session->{SessionID} properties.
  The use of these properties as methods is deprecated, but 
  backwards compatibility will remain.  Updated ./eg/session.asp
  to use these new properties.

 +Implemented $Response->{PICS} which if set sends out a PICS-Label
  HTTP header, useful for ratings.

 +Implemented $Response->{CacheControl} and $Response->{Charset} members.
  By default, CacheControl is 'private', and this value gets sent out
  every request as HTTP header Cache-Control.  Charset appends itself
  onto the content type header.

 +Implemented $Request->BinaryRead(), $Request->{TotalBytes},
  documented them, and updated ./eg/form.asp for an example usage. 

 +Implemented $Response->BinaryWrite(), documented, and created
  and example in ./eg/binary_write.htm

 +Implemented $Server->MapPath() and created example of its use
  in ./eg/server.htm

 -$Request->Form() now reads file uploads correctly with 
  the latest CGI.pm, where $Request->Form('file_field') returns
  the actual file name uploaded, which can be used as a file handle
  to read in the data.  Before, $Request->Form('file_field') would
  return a glob that looks like *Fh::filename, so to get the file
  name, you would have to parse it like =~ s/^\*Fh\:\://,
  which you no longer have to do.  As long as parsing was done as
  mentioned, the change should be backwards compatible.

 +Updated  +enhanced documentation on file uploads.  Created extra
  comments about it as an FAQ, and under $Response->Form(), the latter
  being an obvious place for a developer to look for it.

 +Updated ./eg/file_upload.asp to show use of non file form data, 
  with which we had a bug before.

 +Finished retieing *STDIN to cached STDIN contents, so that 
  CGI input routines may be used transparently, along side with
  use of $Request->Form()

 +Cleaned up and optimized $Request code

 +Updated documentation for CGI input & file uploads.  Created
  file upload FAQ.

 +Reworked ./eg/cgi.htm example to use CGI input routines
  after doing a native read of STDIN.

 ++Added dynamic includes with <!--include file=file args=@args-->
  extension.  This style of include is compiled as an anonymous sub & 
  cached, and then executed with @args passed to the subroutine for 
  execution.  This is include may also be rewritten as a new API 
  extension: $Response->Include('file', @args)

 +Added ./eg/compiled_includes.htm example documenting new dynamic includes.

 +Documented SSI: native file includes, and the rest with filtering 
  to Apache::SSI

 +Turned the documentation of Filter config to value of Off so 
  people won't cut and paste the On config by default.

 +Added SecureSession config option, which forces session cookie to 
  be sent only under https secured www page requests.

 +Added StateDB config option allows use of DB_File for $Session, since 
  default use of SDBM_File is limited.  See StateDB in README.

 +file include syntax w/o quotes supported like <!--#include file=test.inc-->

 +Nested includes are supported, with includes including each other.
  Recursive includes are detected and errors out when an include has been 
  included 100 times for a script.  Better to quit early than 
  have a process spin out of control. (PORTABLE ? probably not)

 +Allow <!--include file=file.inc--> notation w/o quotes around file names

 -PerlSetEnv apache conf setting now get passed through to 
  $Request->ServerVariables. This update has ServerVariables 
  getting data from %ENV instead of $r->cgi_env

 +README FAQ for PerlHandler errors


=item $VERSION = 0.08; $DATE="02/06/1999";

 ++SSI with Apache::Filter & Apache::SSI, see config options & ./eg files
  Currently filtering only works in the direction Apache::ASP -> Apache::SSI,
  will not work the other way around, as SSI must come last in a set of filters

 +SSI file includes may reference files in the Global directory, better 
  code sharing

 - <% @array... %> no longer dropped from code.

 +perl =pod comments are stripped from script before compiling, and associated
  PodComments configuration options.

 +Command line cgi/asp script takes various options, and allows execution
  of multiple asp scripts at one time.  This script should be used for
  command line debugging.  This is also the beginning of building
  a static site from asp scripts with the -b option, suppressing headers.

 +$Response->AddHeader('Set-Cookie') works for multiple cookies.

 -$Response->Cookies('foo', '0') works, was dropping 0 because of boolean test

 -Fixed up some config doc errors.


=item $VERSION = 0.07; $DATE="01/20/1999";

 -removed SIG{__WARN__} handler, it was a bad idea.

 -fixes file locking on QNX, work around poor flock porting

 +removed message about Win32::OLE on UNIX platforms from Makefile.PL

 -Better lock garbage collection.  Works with StatINC seamlessly.

 -Multiple select forms now work in array context with $Response->Form()
	@values = $Response->Form('multi');

 -Better CGI.pm compatibility with $r->header_out('Content-type'),
  improved garbage collection under modperl, esp. w/ file uploads


=item $VERSION = 0.06; $DATE="12/21/1998";

 +Application_OnStart & Application_OnEnd event handlers support.

 -Compatible with CGI.pm 2.46 headers() 

 -Compatible with CGI.pm $q = new CGI({}), caveat: does not set params 

 +use strict; followed by use of objects like $Session is fine.

 -Multiple cookies may be set per script execution.

 +file upload implemented via CGI.pm

 ++global.asa implemented with events Session_OnStart and Session_OnEnd
  working appropriately.

 +StateDir configuration directive implemented.
  StateDir allows the session state directory to be specified separately 
  from the Global directory, useful for operating systems with caching file 
  systems.

 +StateManager config directive.  StateManager specifies how frequently
  Sessions are cleaned up, with 10 (default) meaning that old Sessions
  will be cleaned up 10 times per SessionTimeout period (default 20 minutes).

 +$Application->SessionCount() implemented, non-portable method.
	: returns the number of currently active sessions

 -STOP button fix.  Users may hit STOP button during script 
  execution, and Apache::ASP will cleanup with a routine registered
  in Apache's $r->register_cleanup.  Works well supposedly.

 +PerlScript compatibility work, trying to make ports smoother.
	: Collection emulator, no ->{Count} property
	: $.*(.*)->{Item} parsed automatically, 
	  shedding the ->{Item} for Collection support (? better way ?)
	: No VBScript dates support, just HTTP RFC dates with HTTP::Date
	: Win32::OLE::in not supported, just use "keys %{$Collection}"	

 +./cgi/asp script for testing scripts from the command line
	: will be upgraded to CGI method of doing asp
	: is not "correct" in anyway, so not documented for now
	  but still useful

 +strips DOS carriage returns from scripts automatically, so that
  programs like FrontPage can upload pages to UNIX servers
  without perl choking on the extra \r characters.


=item $VERSION = 0.05; $DATE="10/19/1998";

 +Added PERFORMANCE doc, which includes benchmarks  +hints.

 +Better installation warnings and errors for other modules required. 

 -Turned off StatINC in eg/.htaccess, as not everyone installs Devel::Symdump

 -Fixed AUTOLOAD state bug, which wouldn't let you each through state
  objects, like %{$Session}, or each %$Session, (bug introduced in v.04)

 +Parses ASP white space better.  HTML output matches author's intent
  by better dealing with white space surrounding <% perl blocks %>

 -Scalar insertion code <%=$foo%> can now span many lines.

 +Added include.t test script for includes.

 +Script recompiles when included files change.

 +Files can be included in script with 
  SSI <!--#include file="filename"--> syntax, needs to be
  done in ASP module to allow compilation of included code and html 
  into script.  Future chaining with Apache::SSI will allow static 
  html includes, and other SSI directives


=item $VERSION = 0.04; $DATE="10/14/1998";

 +Example script eg/cgi.htm demonstrating CGI.pm use for output.

 +Optimized ASP parsing, faster and more legible executing code
	: try 'die();' in code with setting PerlSetVar Debug 2

 +Cleaned up code for running with 'use strict'

 -Fixed directory handle leak on Solaris, from not closing after opendir()

 +StatINC overhaul.  StatINC setting now works as it should, with 
  the caveat that exported functions will not be refreshed.

 +NoState setting optimization, disallows $Application & $Session

 +$Application->*Lock() functions implemented

 -SoftRedirect setting for those who want scripts to keep running
  after a Redirect()

 +SessionSerialize setting to lock session while script is running
	: Microsoft ASP style session locking
	: For a session, scripts execute one at a time 
	: NOT recommended use, please see note.

 -MLDBM can be used for other things without messing up internal use
	: before if it was used with different DB's and serializers,
	  internal state could be lost.

 --State file locking.  Corruption worries, and loss of data no more.

 +CGI header support, developer can use CGI.pm for *output*, or just print()
	: print "Set-Cookie: test=cookie\n", and things will just work
	: use CGI.pm for output
	: utilizes $r->send_cgi_header(), thanks Doug!

 +Improved Cookie implementation, more flexible and complete
	- Domain cookie key now works
	: Expire times now taken from time(), and relative time in sec
	: Request->Cookies() reading more flexible, with wantarray()
	  on hash cookie values, %hash = $Request->Cookie('test');

 -make test module naming correction, was t.pm, now T.pm for Unix

 +POD / README cleanup, formatting and HTML friendly.


=item $VERSION = 0.03; $DATE="09/14/1998";

 +Installation 'make test' now works

 +ActiveX objects on Win32 implemented with $Server->CreateObject() 

 +Cookies implemented: $Response->Cookies() & $Request->Cookies()

 -Fixed $Response object API, converting some methods to object members.
  Deprecated methods, but backwards compatible.

 +Improved error messaging, debug output

 +$, influences $Response->Write(@strings) behavior

 +perl print() works, sending output to $Response object

 +$Response->Write() prints scalars, arrays, and hashes.  Before only scalars.

 +Begin implementation of $Server object.

 +Implemented $Response->{Expires} and $Response->{ExpiresAbsolute}

 +Added "PerlSetVar StatINC" config option

 +$0 is aliased to current script filename

 +ASP Objects ($Response, etc.) are set in main package
  Thus notation like $main::Response->Write() can be used anywhere.


=item $VERSION = 0.02; $DATE="07/12/1998";

 ++Session Manager, won't break under denial of service attack

 +Fleshed out $Response, $Session objects, almost full implementation.

 +Enormously more documentation.

 -Fixed error handling with Debug = 2.

 -Documentation fixed for pod2man support.  README now more man-like.

 -Stripped \r\n dos characters from installation files

 -755 mode set for session state directory when created

 -Loads Win32/OLE properly, won't break with UNIX


=item $VERSION = 0.01; $DATE="06/26/1998";

 Syntax Support
 --------------
 Initial release, could be considered alpha software.
 Allows developers to embed perl in html ASP style.

 <!-- sample here -->
 <html>
 <body>
 <% for(1..10) { %>
 	counting: <%=$_%> <br>
 <% } %>
 </body>
 </html>

 ASP Objects
 -----------
 $Session, $Application, $Response, $Request objects available
 for use in asp pages.

 $Session & $Application data is preserved using SDBM files.

 $Session id's are tracked through the use of cookies.

 Security
 --------
 Timeouts any attempt to use a session id that doesn't already 
 exist.  Should stop hackers, since there is no wire speed guessing
 cookies.

=head1 LICENSE

Copyright (c) 1998-2008, Josh Chamas, Chamas Enterprises Inc. 
All rights reserved.  This program is free software; you can 
redistribute it and/or modify it under the same terms as Perl itself.

Apache::ASP is a perl native port of Active Server Pages for Apache
and mod_perl.  

=cut



