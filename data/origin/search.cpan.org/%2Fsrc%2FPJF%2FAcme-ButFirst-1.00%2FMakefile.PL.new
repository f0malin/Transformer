use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::ButFirst',
    VERSION_FROM      => 'lib/Acme/ButFirst.pm', # finds $VERSION
    PREREQ_PM         => {
	'Filter::Simple' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/ButFirst.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Fenwick <pjf@cpan.org>') : ()),
);
