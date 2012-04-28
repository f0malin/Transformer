require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Digest',
    'VERSION_FROM' => 'Digest.pm',
    ($] >= 5.008 ? ('INSTALLDIRS'  => 'perl') : ()),
    ABSTRACT_FROM => 'Digest.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.004',
    'PREREQ_PM'    => {
        'MIME::Base64' => 0,
        'Test::More'   => '0.47'
    },
    META_MERGE => {
        resources => {
            repository => 'http://github.com/gisle/digest',
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
