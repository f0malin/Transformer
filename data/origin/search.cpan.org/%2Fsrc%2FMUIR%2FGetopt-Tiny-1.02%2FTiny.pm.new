
package Getopt::Tiny;

use vars qw($VERSION);
$VERSION = 1.02;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(getopt);

use strict;

use vars qw($usageHandle);
$usageHandle = 'STDERR';

sub getopt
{
	my ($avref, $flagref, $switchref, $remainder) = @_;
	unless (defined($avref)) {
		$avref = \@::ARGV;
		$flagref = \%::flags;
		$switchref = \%::switches;
	}

	while (@$avref) {
		$_ = shift @$avref;
		unless (/^-(no)?(.+)$/) {
			if ($remainder) {
				unshift(@$avref, $_);
				return;
			}
			callusage($_, $flagref, $switchref, $remainder);
			return;
		}
		if (@$avref) {
			if (exists $flagref->{$2}) {
				if (ref $flagref->{$2} eq 'ARRAY') {
					my $f = $2;
					for (;;) {
						push(@{$flagref->{$f}}, shift @$avref);
						last unless @$avref && $avref->[0] =~ /^[^-]/;
					}
				} elsif (ref $flagref->{$2} eq 'HASH') {
					my $f = $2;
					for (;;) {
						my $v = shift @$avref;
						if ($v =~ /^(.*)=(.*)/) {
							$flagref->{$f}->{$1} = $2;
						} else {
							callusage("$_ $v", $flagref, $switchref, $remainder);
						}
						last unless @$avref && $avref->[0] =~ /^[^-].*=/;
					} 
				} else {
					${$flagref->{$2}} = shift @$avref;
				}
				next;
			}
		}
		if (exists $switchref->{$2}) {
#			if (ref $switchref->{$2} eq 'HASH') {
#				if (@$avref) {
#					$switchref->{$2}->{shift @$avref} = ! $1;
#				} else {
#					callusage($_, $flagref, $switchref, $remainder);
#				}
#			} else {
				${$switchref->{$2}} = ! $1;
#			}
			next;
		}
		callusage($_, $flagref, $switchref, $remainder);
		return;
	}
}

sub callusage
{
	my ($arg, $flagref, $switchref, $remainder) = @_;
	my ($package, $filename) = (caller(1))[0,1];

	{
		no strict;
		if (defined &{"${package}::usage"}) {
			&{"${package}::usage"}($arg);
			return;
		}
	}

	my $o = select($usageHandle || 'STDERR');

	print "$0: unknown option '$arg'\n";

	$remainder = 'args' if $remainder > 0;
	print "Usage: $0 [flags] [switches] $remainder\n";

	usage($filename, $flagref, $switchref);

	select($o);
}

sub usage
{
	my ($filename, $flagref, $switchref) = @_;
	unless (defined $filename) {
		$filename = (caller[0])[1];
		$flagref = \%::flags;
		$switchref = \%::switches;
	}

	my %comment;
	open(USAGESOURCEFILE, "<$filename") or die "open $filename: $!";
	while (<USAGESOURCEFILE>) {
		last if /^# begin usage info/;
	}
	while (<USAGESOURCEFILE>) {
		if (/^\s*["'](\S+?)["']\s*=\>.*?\#\s*(\S.*)/) {
			$comment{$1} = $2;
		}
		last if /^# end usage info/;
	}
	if (%$flagref) {
		for my $f (sort keys %$flagref) {
			if (ref $flagref->{$f} eq 'ARRAY') {
				printf "\t-%-25s %s\n", "$f value ...", $comment{$f}||'';
			} elsif (ref $flagref->{$f} eq 'HASH') {
				printf "\t-%-25s %s\n", "$f key=value ...", $comment{$f}||'';
			} else {
				printf "\t-%-25s %s\n", "$f value", $comment{$f}||'';
			}
		}
	}
	if (%$switchref) {
		for my $f (sort keys %$switchref) {
#			if (ref $switchref->{$f} eq 'HASH') {
#				printf "\t-%-25s %s\n", "[no]$f key", $comment{$f}||'';
#			} else {
				printf "\t-[no]%-21s %s\n", $f, $comment{$f}||'';
#			}
		}
	}
}

1;
