use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'IPC::Run3',
    VERSION_FROM  => 'lib/IPC/Run3.pm',
    ABSTRACT_FROM => 'lib/IPC/Run3.pm',
    AUTHOR        => 'Barrie Slaymaker <barries@slaysys.com>',
    (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'open_source') : ()),
    EXE_FILES     => [],
    PREREQ_PM => {
      'Test::More'  => '0.31',
      'Time::HiRes' => 0,
      ($^O =~ /Win32/ ? (Win32 => 0) : ())
    },
    NO_META       => 1,
    clean => { FILES => [ "t/test.txt", "t/utf8.txt" ] },
);
