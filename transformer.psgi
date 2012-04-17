use strict;
use warnings;

use utf8;
use Smart::Comments "###";
use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use Text::Xslate qw(mark_raw);

our $config = {
    host_map => {
        'www.perlchina.org' => 'www.perl.org',
        'perlchina.org' => 'www.perl.org',
        '127.0.0.1:5000' => 'www.perl.org',
        'learn.perlchina.org' => 'learn.perl.org',
    },
    cache_timeout => 600,
    cache_timeout_rand => 120,
};

our $ua = LWP::UserAgent->new;
our $ua2 = LWP::UserAgent->new;
$ua2->max_redirect(0);

our $tx = Text::Xslate->new();

our %access_count_of = ();
our $last_timeout = 0;
our $timeout_interval = 300;

sub is_timeout {
    if (time - $last_timeout > $timeout_interval) {
        time_out();
        $last_timeout = time;
    }
}

sub time_out {
    my @sorted_keys = sort { $access_count_of{$b} <=> $access_count_of{$a} } keys(%access_count_of);
    print "access count:\n";
    for my $key (@sorted_keys) {
        print "\t", $key, "\t", $access_count_of{$key}, "\n";
    }
}

sub calc_url {
    my $env = shift;
    return $env->{'psgi.url_scheme'} . "://" . $config->{host_map}->{$env->{'HTTP_HOST'}} . $env->{"REQUEST_URI"};
}

sub calc_origin {
    my $env = shift;
    my $path = "data/origin/".$config->{host_map}->{$env->{'HTTP_HOST'}} . "/";
    my $file = $path . uri_escape($env->{"REQUEST_URI"}) . ".new";
    return ($path, $file);
}

sub store_origin {
    my $env = shift;
    my $res = shift;
    my ($path, $file) = calc_origin($env);
    mkdir $path unless -e $path;
    open my $fh, ">", $file or die $!;
    print $fh $res->content;
    close $fh;
}

sub cat_file {
    my $file = shift;
    open my $fh, "<", $file or die $!;
    my $content;
    {
        local $/ = undef;
        $content = <$fh>;
    }
    close $fh;
    return \$content;
}

sub tx_file {
    my $file = shift;
    my $str = $tx->render($file);
    utf8::encode($str);
    return \$str;
}

sub get_content {
    my $env = shift;
    my ($path, $file) = calc_origin($env);

    # find translated file first
    my $trans_file = $file;
    $trans_file =~ s{\borigin\b}{trans};
    $trans_file =~ s{\.new$}{.old};
     if (-e $trans_file) {
        ### translated: $trans_file
        my $rcontent = tx_file($trans_file);
        return [200, ['Content-Type' =>  'text/html;charset=utf-8', 'Content-Length' => length($$rcontent)], [$$rcontent]];
    } else {
        ### no translation: $file, $trans_file
        $access_count_of{$file} ++;
    }

    if (-e($file) && (time - (stat($file))[9] < $config->{cache_timeout}+int(rand($config->{cache_timeout_rand})))) {
        ### cached: $file
        my $rcontent = cat_file($file);
        return [200, ['Content-Type' =>  'text/html;charset=utf-8', 'Content-Length' => length($$rcontent)], [$$rcontent]];
    } else {
        ### not yet cached: $file
    }
    my $res = $ua->get(calc_url($env));
    my $content = $res->content;
    if (utf8::is_utf8($content)) {
        utf8::encode($content);
    }
    my $content_type = $res->header('content-type');
    if ($res->code =~ m{^2} && $content_type =~ m{text/html}i) {
        ### to store: $file
        $content_type = "text/html;charset=utf-8";
        store_origin($env, $res);
    } else {
        ### don't store: $file
    }
    if ($res->code =~ m{^5} && -e $file) {
        ### failback to cache: $file
        my $rcontent = cat_file($file);
        return [200, ['Content-Type' =>  'text/html;charset=utf-8', 'Content-Length' => length($$rcontent)], [$$rcontent]];
    }
    my @headers = ('Content-Type' => $content_type);
    my $content_length = $res->header('content-length');
    if ($content_length) {
        push @headers, 'Content-Length' => $content_length;
    }
    ### out: $file
    return [ $res->code, \@headers, [$content]];
}

sub get_pod {
    my ($env, $module) = @_;

    # get module' src's url
    my $res = $ua2->get("http://search.cpan.org/perldoc?" . $module);
    if ($res->code eq 302) {
        my $url = $res->header('location');
        ### pod url: $url
        $url =~ s{^/~([^/]+)}{'http://cpansearch.perl.org/src/'.uc($1)}e;
        ### pod source url: $url
        my $res2 = $ua2->get($url);
        my $content_type = $res2->header('content-type');
        my $content_length = $res2->header('content-length');
        my @headers = ('Content-Type' => $content_type);
        if ($content_length) {
            push @headers, 'Content-Length' => $content_length;
        }
        return [$res2->code, \@headers, [$res2->content]];
    } else {
        return [404, ['Content-Type' => 'text/plain', 'Content-Length' => 14], ['no this module']];
    }
}

sub {
    my $env = shift;
    #### $env
    is_timeout;
    if ($env->{'REQUEST_URI'} =~ m{^/perldoc\?(.*)$}) {
        my $module = $1;
        ### pod module : $module
        return get_pod($env, $module);
    } else {
        return get_content($env);
    }
}
