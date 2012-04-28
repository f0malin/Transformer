use 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'Pod2WinHlp',
    'PREREQ_PM' => { 'Pod::Parser' => ''},
    'EXE_FILES' => [qw(pod2rtf)],
    'PMLIBDIRS'   => [qw(Pod)],
    'linkext' => { LINKTYPE => ''},
    'dist'     => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
    'VERSION_FROM' => 'Pod/Rtf.pm',
);

