use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl6::Slurp::Interpret',
    VERSION_FROM      => 'lib/Perl6/Slurp/Interpret.pm', # finds $VERSION
    PREREQ_PM         => { 
                            Inline::Files => 0 ,
                            Perl6::Slurp => 0
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Perl6/Slurp/Interpret.pm', # retrieve abstract from module
       AUTHOR         => 'Christopher Brown <ctbrown@cpan.org>') : ()),
);
