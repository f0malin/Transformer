use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Date::Transform',
    'VERSION_FROM' => 'Transform.pm',      # finds $VERSION
    'PREREQ_PM'    => {
        Switch      	=> 0,
        Tie::IxHash 	=> 0,
        POSIX       	=> 0
    },                                     # e.g., Module::Name => 1.1
    (
        $] >= 5.006
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'Transform.pm',    # retrieve abstract from module
            AUTHOR => 'Christopher Brown <chris.brown -at- cal.berkeley.edu>'
          )
        : ()
    ),
);

