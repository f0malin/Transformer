use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Voting::Condorcet::RankedPairs',
    VERSION_FROM      => 'lib/Voting/Condorcet/RankedPairs.pm', # finds $VERSION
    PREREQ_PM         => {
    	'Graph' => 0.80,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Voting/Condorcet/RankedPairs.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Fenwick <pjf@cpan.org>') : ()),
);
