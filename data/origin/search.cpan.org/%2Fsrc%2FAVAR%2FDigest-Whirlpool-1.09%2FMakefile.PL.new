use strict;
use ExtUtils::MakeMaker;

my $dist = 'Digest-Whirlpool';

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
 },
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.nix.is/?p=avar/pm/$dist",
 },
);

WriteMakefile(
	NAME => 'Digest::Whirlpool',
    AUTHOR => do { use utf8; 'Ævar Arnfjörð Bjarmason <avar@cpan.org>' },,
    ABSTRACT_FROM => 'Whirlpool.pm',
    VERSION_FROM => 'Whirlpool.pm',
    LICENSE => 'perl',
    EXE_FILES => [
        'script/whirlpoolsum',
    ],
    PREREQ_PM => {
        # script/
        'Digest'       => 0, # 5.007003
        'Pod::Usage'   => 0, # 5.006
        'Getopt::Long' => 0, # 5

        # lib/
        'Digest::base' => 0, # 5.008003
        'MIME::Base64' => 0, # 5.007003
    },
    META_MERGE => \%META,
);
