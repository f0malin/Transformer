use strict;
use warnings;

use Smart::Comments "###";
use File::Copy qw(cp);
use URI::Escape qw(uri_escape);
use LWP::Simple qw(getstore is_success);

my $url = shift @ARGV;

die "wrong url, must be something under *.perl.org" unless $url =~ m{^http://([^/\.]+\.perl\.org)(/.*)$};

my $domain = $1;
my $path = $2;

### $domain
### $path

my $origin = "data/origin/$domain/". uri_escape($path) . ".old";

### $origin

my $trans = "data/trans/$domain/". uri_escape($path) . ".old";

### $trans

if (-e $origin) {
    print "origin exists, this file is translating or has been translated\n";
    exit;
}

my $rc = getstore($url, $origin);
if (is_success($rc)) {
    cp $origin, $trans;
} else {
    unlink $origin;
}

print "done!\n";
