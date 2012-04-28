#!perl -w

use Test::More;
plan skip_all => "Test::More 0.31 required for no_ending()" if $Test::More::VERSION <= 0.31;
plan skip_all => "tests fail on Win32 and Cygwin" if $^O =~ /^(MSWin32|cygwin)$/;
plan tests => 5;

use IPC::Run3;
use strict;

sub techo
{
    my $exp = shift;
    my $got;
    run3 [ $^X, "-e", "print '$exp'" ], \undef, \$got, \undef;
    return ($got, $exp);
}

my ($got, $exp);

# force IPC::Run3 into populating %fh_cache 
# by running techo once in the parent
($got, $exp) = techo("parent$$ before fork");
is($got, $exp, "parent before fork");

if (my $pid = fork)
{
    # parent
    my $kid = waitpid($pid, 0);
    ok($kid == $pid && $? == 0, "single child");
}
else
{
    # child

    # ask Test::More not to run its END block in the child
    Test::More->builder->no_ending(1);

    my ($got, $exp) = techo("child$$");
    if ($exp eq $got)
    {
	exit(0);
    }
    else
    {
	diag qq[child $$: expected "$exp", got "$got"\n];
	exit(1);
    }
}

($got, $exp) = techo("parent$$ after fork");
is($got, $exp, "parent after fork");

# now run several child processes in parallel,
# all calling run3 repeatedly
my ($nkids, $nruns) = (5, 10);	# usually enough, even on uniprocessor systems

my @kids;
for (1..$nkids)
{
    if (my $kid = fork)
    {
	push @kids, $kid;
    }
    else
    {
        # child
	Test::More->builder->no_ending(1);

	for (1..$nruns)
	{
	    my ($got, $exp) = techo("child$$:run$_");
	    next if $exp eq $got;

	    diag qq[child $$: expected "$exp", got "$got"\n];
	    exit(1);
	}

	exit(0);
    }
}

my $nok = 0;
while (@kids)
{
    my $kid = shift @kids;
    my $pid = waitpid($kid, 0);
    $nok++ if $pid == $kid && $? == 0;
}
ok($nok == $nkids, "$nkids parallel child processes, each run $nruns times");

($got, $exp) = techo("parent$$ after parallel forks");
is($got, $exp, "parent after parallel forks");

