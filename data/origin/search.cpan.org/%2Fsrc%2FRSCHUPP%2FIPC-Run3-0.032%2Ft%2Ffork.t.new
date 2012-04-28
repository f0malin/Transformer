use Test::More;
use IPC::Run3;
use POSIX;
use strict;

if ($^O =~ /Win32/) { plan skip_all => 'fork tests fail on Windows'; }
else		    { plan tests => 5; }

sub echo
{
    my $exp = shift;
    my $got;
    run3 [ $^X, "-e", "print '$exp'" ], \undef, \$got, \undef;
    return ($got, $exp);
}

my ($got, $exp);

# force IPC::Run3 into populating %fh_cache 
# by running echo once in the parent
($got, $exp) = echo("parent$$");
is($got, $exp, "echo parent before fork");

if (my $pid = fork)
{
    # parent
    ok(waitpid(-1, 0) > 0 && $? == 0, "echo child");
}
else
{
    # child
    my ($got, $exp) = echo("child$$");

    # don't use exit() or die() because they will run the END block
    # set up by Test::More in the child (so that it gets run twice)
    POSIX::_exit(0) if $exp eq $got;

    warn qq[child $$: expected "$exp", got "$got"\n];
    POSIX::_exit(1);
}

($got, $exp) = echo("parent$$");
is($got, $exp, "echo parent after fork");

# now run several child processes in parallel,
# all calling run3 repeatedly
my ($kids, $runs) = (5, 10);	# usually enough, even on uniprocessor systems

for (1..$kids)
{
    unless (fork)
    {
        # child
	for (1..$runs)
	{
	    my ($got, $exp) = echo("child$$:run$_");
	    POSIX::_exit(0) if $exp eq $got;

	    warn qq[child $$: expected "$exp", got "$got"\n];
	    POSIX::_exit(1);
	}
    }
}

my ($failed, $reaped);
while (waitpid(-1, 0) > 0)
{
    $reaped++;
    $failed++ unless $? == 0;
}
ok($reaped == $kids, "run $kids parallel child processes");
ok($failed == 0, "check for filehandle crossover");
