use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::OSDc',
    EXE_FILES         => ['bin/OSDc'],
    VERSION_FROM      => 'lib/Acme/OSDc.pm', # finds $VERSION
    PMLIBDIRS         => ['lib'],
    PREREQ_PM         => { 'Acme::Ook' => '0.11' }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/OSDc.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Fenwick <pjf@cpan.org>') : ()),
);
