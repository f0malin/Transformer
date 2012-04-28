use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::Excel::Refresh',
    'VERSION_FROM'	=> 'Refresh.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			Win32::OLE => 0
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (
	  ABSTRACT_FROM => 'Refresh.pm', # retrieve abstract from module
       AUTHOR     => 'Christopher Brown <ctbrown@cpan.org>'
	) : ()),
);
