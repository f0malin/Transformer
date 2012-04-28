use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'IPC::Run3',
    VERSION_FROM  => 'lib/IPC/Run3.pm',
    EXE_FILES     => [],
    PREREQ_PM => {
      'Time::HiRes' => 0,
      ($^O =~ /Win32/ ? (Win32 => 0) : ())
    },
    clean => { FILES => "t/test.txt" },
);
