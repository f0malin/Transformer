use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'IPC::Run3',
    VERSION_FROM  => 'lib/IPC/Run3.pm',
    ABSTRACT_FROM => 'lib/IPC/Run3.pm',
    AUTHOR        => 'Barrie Slaymaker <barries@slaysys.com>',
    (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'open_source') : ()),
    EXE_FILES  => [],
    PREREQ_PM  => {
      'Test::More'  => '0.31',
      'Time::HiRes' => 0,
      ($^O =~ /Win32/ ? (Win32 => 0) : ())
    },
    META_MERGE => {
      resources => {
        repository => 'http://github.com/rjbs/ipc-run3/',
      },
      no_index => {
        dir  => [ qw(lib/IPC/Run3)   ],
        file => [ qw(bin/run3profpp) ],
      },
    },
    clean => { FILES => [ "t/test.txt", "t/utf8.txt", "t/zz.txt", "t/zz*.t" ] },
);

package MY;

sub postamble
{
    my $self = shift;
    
    my $nlines = 1000;
    my $zz_txt = "t/zz.txt";

    open my $fh, ">", $zz_txt or die "can't create $zz_txt: $!";
    for (my $i = 1; $i <= $nlines; $i++)
    {
	print $fh "this is line $i\n";
    }
    close $fh;

    foreach my $run3_after (5, 10, 50, 100, 200, 500)
    {
	# test: read from stdin redirected to t/zz.txt
	{
	    my $zz_t = sprintf "t/zz_stdin_%03d.t", $run3_after;
	    open my $fh, ">", $zz_t or die "can't create $zz_t: $!";
	    print $fh <<"...";
#!perl

system qq[\$^X -e "require 't/read-stdin.pl'; read_stdin($nlines, $run3_after);" < $zz_txt];
exit \$?;
...
	    close $fh;
	}

	# test: read from t/zz.txt given on command line
	{
	    my $zz_t = sprintf "t/zz_argv_%03d.t", $run3_after;
	    open my $fh, ">", $zz_t or die "can't create $zz_t: $!";
	    print $fh <<"...";
#!perl

system qq[\$^X -e "require 't/read-stdin.pl'; read_stdin($nlines, $run3_after);" $zz_txt];
exit \$?;
...
	    close $fh;
	}
    }
}

