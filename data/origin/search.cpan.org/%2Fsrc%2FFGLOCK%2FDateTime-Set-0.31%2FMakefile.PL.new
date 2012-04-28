use strict;

use ExtUtils::MakeMaker;
use vars qw( %conflicts $has_conflicts );

sub conflicts {
    my ( $module, $version ) = @_;
    eval "use $module";
    my $module_version = eval "\$".$module."::VERSION";
    if ( defined $module_version && $module_version < $version )
    {
        warn " * ERROR: This version of DateTime::Set conflicts with\n".
             "   installed module \"$module\" Version \"$module_version\"\n";
        $has_conflicts = 1;
    }
}

%conflicts = (
        'DateTime::Event::Recurrence' => '0.10',
        'DateTime::Event::ICal'       => '0.07',
        'DateTime::Event::Random'     => '0.03',
        'DateTime::Event::Cron'       => '0.0601',
        'DateTime::Event::Sunrise'    => '0.0501', # cvs ok; CPAN not ok
        'DateTime::Event::Chinese'    => '0',      # untested
        'DateTime::Event::Lunar'      => '0',      # untested
        'DateTime::Event::SolarTerm'  => '0',      # untested
);

$has_conflicts = 0;
for ( keys %conflicts )    
{
    conflicts ( $_, $conflicts{$_} );
}
if ( $has_conflicts )
{
    warn "ERRORS/WARNINGS FOUND IN PREREQUISITES.  You may wish to update the versions\n".
         "of the modules indicated above before proceeding with this installation.\n\n";
}

WriteMakefile( NAME         => 'DateTime::Set',
               VERSION_FROM => 'lib/DateTime/Set.pm',
               AUTHOR       => 'Flavio S. Glock <fglock@gmail.com>',
               ABSTRACT     => 'DateTime set objects',

               PREREQ_PM    => { 'DateTime' => 0.12,
                                 'Set::Infinite' => 0.59,
                                 'Test::More'  => 0,
                               },
               PL_FILES     => { },  # ignore Build.PL
);
