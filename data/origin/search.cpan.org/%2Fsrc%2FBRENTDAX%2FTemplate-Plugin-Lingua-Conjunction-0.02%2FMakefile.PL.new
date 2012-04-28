use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::Lingua::Conjunction',
    VERSION_FROM      => 'lib/Template/Plugin/Lingua/Conjunction.pm', # finds $VERSION
    PREREQ_PM         => {
                            Lingua::Conjunction => 1.99,
                            Template => 2.07
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/Lingua/Conjunction.pm', # retrieve abstract from module
       AUTHOR         => 'Brent Royal-Gordon <brentdax@cpan.org>') : ()),
);
