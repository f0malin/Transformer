use strict;
use warnings;

use utf8;
use Smart::Comments "###";
use LWP::UserAgent;
use URI::Escape qw(uri_escape);

our $config = {
    host_map => {
        'localhost:5000' => 'www.perl.org',
    },
    cache_timeout => 600,
    cache_timeout_rand => 120,
};

our $ua = LWP::UserAgent->new;

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

sub get_content {
    my $env = shift;
    my ($path, $file) = calc_origin($env);

    # find translated file first
    my $trans_file = $file;
    $trans_file =~ s{\borigin\b}{trans};
    $trans_file =~ s{\.new$}{.old};
     if (-e $trans_file) {
        ### translated: $trans_file
        my $rcontent = cat_file($trans_file);
        return [200, ['Content-Type' =>  'text/html;charset=utf-8', 'Content-Length' => length($$rcontent)], [$$rcontent]];
    } else {
        ### no translation: $file, $trans_file
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

sub {
    my $env = shift;
    #### $env
    return get_content($env);
}
