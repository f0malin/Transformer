
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Getopt::Tiny',
	'DISTNAME' => 'Getopt-Tiny',
	'VERSION_FROM' => 'Tiny.pm',
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Parse arguments with very little code',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: Tiny.pod
\tpod2text Tiny.pod >README

END_OF_POSTAMBLE
}
