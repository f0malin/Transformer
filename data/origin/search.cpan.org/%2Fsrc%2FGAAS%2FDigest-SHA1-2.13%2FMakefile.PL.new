require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Digest::SHA1',
    'VERSION_FROM' => 'SHA1.pm',
    'ABSTRACT'     => 'Perl interface to the SHA-1 algorithm',
    'AUTHOR'       => 'Gisle Aas <gisle@activestate.com>',
    'LICENSE'      => "perl",
    'MIN_PERL_VERSION' => 5.004,
    'PREREQ_PM'    => {
	                'Digest::base' => '1.00',
                      },
    'META_MERGE'   => {
	repository => 'http://github.com/gisle/digest-sha1',
    },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f "NOTES.txt";
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
