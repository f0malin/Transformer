use strict;
use warnings;

use Smart::Comments;
use LWP::UserAgent;
use File::Copy qw(cp);

my $module = shift @ARGV;
### $module
die "Usage : perl $0 <modulename>" unless $module;

my $ua = LWP::UserAgent->new;
$ua->max_redirect(0);

my $res = $ua->get("http://search.cpan.org/perldoc?". $module);

if ($res->code == 302) {
    my $url = $res->header('location');
    $url =~ s{^/~([^/]+)}{'http://cpansearch.perl.org/src/'.uc($1)}e;
    ### $url

    $module =~ s{::}{-}g;
    my $bfile = "data/origin/cpan/".$module. ".old";
    ### $bfile
    my $tfile = "data/trans/cpan/".$module.".old";
    ### $tfile
    $res = $ua->get($url);
    if ($res->is_success) {
        my $fh;
        open $fh, ">", $bfile or die $!;
        print $fh $res->content;
        close $fh;
        open $fh, ">", $tfile or die $!;
        print $fh $res->content;
        close $fh;
        ### scaffold create succeed
        exit 0;
    }
}

print "no this module", "\n";
