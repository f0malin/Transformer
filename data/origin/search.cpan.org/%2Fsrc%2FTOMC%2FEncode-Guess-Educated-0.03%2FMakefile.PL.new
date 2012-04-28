use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(

    NAME                => "Encode::Guess::Educated",
    AUTHOR              => q{Tom Christiansen <tchrist@perl.com>},
    VERSION_FROM        => "lib/Encode/Guess/Educated.pm",
    ABSTRACT_FROM       => "lib/Encode/Guess/Educated.pm",
    LICENSE  		=> "perl",
    MIN_PERL_VERSION    => 5.10.0,

    PREREQ_PM => { 
	"Carp"		    => 0,
	"Encode"	    => 0,
	"Encode::Guess"	    => 0,
	"Getopt::Long"	    => 0,
	"List::Util"	    => 0,
	"Pod::Usage"	    => 0,
	"Scalar::Util"	    => 0,
	"Test::More" 	    => "0.96",
	"Unicode::Collate"  => 0,
	"Unicode::UCD"	    => 0,
    },

    EXE_FILES => 	=> [ qw( bin/gank ) ],

    dist                => { COMPRESS => "gzip -9f", SUFFIX => "gz", },
    clean               => { FILES => "Enable-Guess-Educated-*" },

);
