package Test::More;     # Test::More work-alike for Perl 5.8.0

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(plan ok is like is_deeply);

use Scalar::Util;

sub plan
{
    my $what = shift;
    if ($what eq 'skip_all') {
        my $reason = shift;
        print("1..0 # SKIP $reason\n");
        exit(0);
    }

    my $tests = shift;
    $| = 1;
    print("1..$tests\n");
}

my $TEST :shared = 1;

sub ok {
    my ($ok, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
        print(STDERR "# FAIL: $name\n") if (! exists($ENV{'PERL_CORE'}));
    }

    return ($ok);
}

sub is
{
    my ($got, $expected, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    my $ok = ("$got" eq "$expected");

    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
        print("#      got: $got\n");
        print("# expected: $expected\n");
        print(STDERR "# FAIL: $name\n") if (! exists($ENV{'PERL_CORE'}));
    }

    return ($ok);
}

sub like
{
    my ($got, $like, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    my $ok = "$got" =~ $like;

    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
        print("#           got: $got\n");
        print("# doesn't match: $like\n");
        print(STDERR "# FAIL: $name\n") if (! exists($ENV{'PERL_CORE'}));
    }

    return ($ok);
}

sub is_deeply
{
    my ($got, $expected, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    my ($ok, $g_err, $e_err) = _compare($got, $expected, {});

    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
        print("#      got: $g_err\n");
        print("# expected: $e_err\n");
        print(STDERR "# FAIL: $name\n") if (! exists($ENV{'PERL_CORE'}));
    }

    return ($ok);
}

sub _compare
{
    my ($got, $exp, $cir_ref) = @_;
    my ($ok, $g_err, $e_err);

    # Undefs?
    if (! defined($got) || ! defined($exp)) {
        return 1 if (! defined($got) && ! defined($exp));
        return (undef, 'undef', "$exp") if (! defined($got));
        return (undef, "$got", 'undef');
    }

    # Not refs?
    if (! ref($got) || ! ref($exp)) {
        # Two scalars
        return ("$got" eq "$exp", "'$got'", "'$exp'")
            if (! ref($got) && ! ref($exp));
        return (undef, "'$got'", "$exp") if (! ref($got));
        return (undef, "$got", "'$exp'");
    }

    # Check classes
    return (undef, "$got", "$exp") if (ref($got) ne ref($exp));

    # Check for circular references
    my $g_addr = threads::shared::_id($got) || Scalar::Util::refaddr($got);
    my $e_addr = threads::shared::_id($exp) || Scalar::Util::refaddr($exp);
    if (exists($cir_ref->{$g_addr})) {
        return 1 if ($cir_ref->{$g_addr} == $e_addr);
        return (undef, "$got", "$exp");
    }

    # Check reftypes
    my $g_ref = Scalar::Util::reftype($got);
    my $e_ref = Scalar::Util::reftype($exp);
    return (undef, "reftype=$g_ref", "reftype=$e_ref") if ($g_ref ne $e_ref);

    # Recursively compare refs or refs
    if ($g_ref eq 'REF') {
        # Add item to circular reference hash
        $cir_ref->{$g_addr} = $e_addr;
        # Recursively compare
        ($ok, $g_err, $e_err) = _compare($$got, $$exp, $cir_ref);
        # Remove item from circular refernce hash
        delete($cir_ref->{$g_addr});
        # Check results
        return 1 if $ok;
        return (undef, "ref of '$$got'", "ref of '$$exp'");
    }

    # Compare scalar refs
    if ($g_ref eq 'SCALAR') {
        return 1 if ("$$got" eq "$$exp");
        return (undef, "ref of '$$got'", "ref of '$$exp'");
    }

    # Compare array refs
    if ($g_ref eq 'ARRAY') {
        my $g_len = scalar(@$got);
        my $e_len = scalar(@$exp);
        return (undef, "array of len $g_len", "array of len $e_len") if ($g_len != $e_len);

        # Compare elements
        for (my $ii=0; $ii<$g_len; $ii++) {
            # Add item to circular reference hash
            $cir_ref->{$g_addr} = $e_addr;
            # Recursively compare
            ($ok, $g_err, $e_err) = _compare($$got[$ii], $$exp[$ii], $cir_ref);
            # Remove item from circular refernce hash
            delete($cir_ref->{$g_addr});
            # Check results
            return (undef, "\$\$got[$ii]=$g_err", "\$\$exp[$ii]=$e_err")
                if ! $ok;
        }
        return 1;  # Same
    }

    # Compare array refs
    if ($g_ref eq 'HASH') {
        my %keys = map { $_ => undef } (keys(%$got), keys(%$exp));
        foreach my $key (keys(%keys)) {
            if (! exists($$got{$key})) {
                my $val = (defined($$exp{$key})) ? $$exp{$key} : 'undef';
                return (undef, "\$\$got{$key} does not exist", "\$\$exp{$key}=$val");
            }
            if (! exists($$exp{$key})) {
                my $val = (defined($$got{$key})) ? $$got{$key} : 'undef';
                return (undef, "\$\$got{$key}=$val", "\$\$exp{$key} does not exist");
            }

            # Add item to circular reference hash
            $cir_ref->{$g_addr} = $e_addr;
            # Recursively compare
            ($ok, $g_err, $e_err) = _compare($$got{$key}, $$exp{$key}, $cir_ref);
            # Remove item from circular refernce hash
            delete($cir_ref->{$g_addr});
            # Check results
            return (undef, "\$\$got{$key}=$g_err", "\$\$exp{$key}=$g_err")
                if ! $ok;
        }
        return 1;  # Same
    }

    # Other ref types - just compare as strings
    return ("$got" ne "$exp", "$got", "$exp");
};

1;
# EOF
