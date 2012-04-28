#!perl -w

require 5.006002;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'HTTP::Date',
    VERSION_FROM => 'lib/HTTP/Date.pm',
    ABSTRACT_FROM => 'lib/HTTP/Date.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.006002,
    PREREQ_PM => {
        'Time::Local' => 0,
    },
    META_MERGE => {
        recommends => {
            'Time::Zone' => 0,
        },
	resources => {
            repository => 'http://github.com/gisle/http-date',
	    MailingList => 'mailto:libwww@perl.org',
        }
    },
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f ".gitignore";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
