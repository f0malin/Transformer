use strict;
use warnings;

package My::Pod;

use base qw(Pod::Simple::HTML);

sub index_as_html {
    return '<div class="toc">' . Pod::Simple::HTML::index_as_html(@_) . '</div>';
}

package main;
    
use utf8;
use Smart::Comments "###";
use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use Text::Xslate qw(mark_raw);
use Pod::Simple::HTML;

our $config = {
    host_map => {
        'www.perlchina.org' => 'www.perl.org',
        'perlchina.org' => 'www.perl.org',
        '127.0.0.1:5000' => 'www.perl.org',
        '121.52.238.55:5000' => 'www.perl.org',
        'learn.perlchina.org' => 'learn.perl.org',
    },
    cache_timeout => 3600,
    cache_timeout_rand => 300,
};

our $ua = LWP::UserAgent->new;
our $ua2 = LWP::UserAgent->new;
$ua2->max_redirect(0);

our $tx = Text::Xslate->new();

our $pod_parser = My::Pod->new();
$pod_parser->perldoc_url_prefix("http://cpan.perlchina.org/perldoc?");
#$pod_parser->html_charset('utf-8');
#$pod_parser->html_encode_chars("<>&");
#$pod_parser->html_header("");
$pod_parser->html_footer("");
$pod_parser->html_header_before_title("<!-- ");
$pod_parser->html_header_after_title(" -->");
$pod_parser->index(1);

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

sub render_pod {
    my $file = shift;
    my $content;
    $pod_parser->output_string(\$content);
    $pod_parser->parse_file($file);
    my $content_length = length($content);
    return [200, ['Content-Type' => 'text/html;charset=utf-8', 'Content-Length' => $content_length], [$content]];
}

sub get_pod {
    my ($env, $module) = @_;

    # 1 - if translation exist
    my $tfile = "data/trans/cpan/$module.old";
    # replace :: to -
    $tfile =~ s{::}{-}g;
    if (-e $tfile) {
        ### use translation: $module, $tfile
        return render_pod($tfile);
    }

    # 2 - elsif cached exist and not expired
    my $cfile = "data/origin/cpan/$module.new";
    # replace :: to -
    $cfile =~ s{::}{-}g;
    if (-e($cfile) && (time - (stat($cfile))[9] < $config->{cache_timeout}+int(rand($config->{cache_timeout_rand})))) {
        ### use cached: $module, $cfile
        return render_pod($cfile);
    }

    # 3 - else fetch remote pod and save it to cache
    # get module' src's url, using ua2 ( don't follow redirects )
    my $res = $ua2->get("http://search.cpan.org/perldoc?" . $module);
    if ($res->code eq 302) {
        my $url = $res->header('location');
        $url =~ s{^/~([^/]+)}{'http://cpansearch.perl.org/src/'.uc($1)}e;
        my $res2 = $ua2->get($url);

        # if is pod
        if ($res2->code == 200) {
            my $content;
            $pod_parser->output_string(\$content);
            $pod_parser->parse_string_document($res2->content);
            my $content_length = length($content);
            # save to cache
            open my $fh, ">", $cfile or die $!;
            print $fh $res2->content;
            close $fh;
            ### fetch from remote: $module, $url, $cfile
            return [200, ['Content-Type' => 'text/html;charset=utf-8', 'Content-Length' => $content_length], [$content]];
        }
    }

    # 4 - if fetch failed, fall back to cache
    if (-e $cfile) {
        ### fall back to cache: $module, $cfile
        return render_file($cfile);
    }
    
    # 5 - if cannot fall back to cache, report error
    ### 404: $module
    return [404, ['Content-Type' => 'text/plain', 'Content-Length' => 14], ['no this module']];
}

sub get_cpan {
    my $env = shift;
    
    my $url = "http://search.cpan.org" . $env->{REQUEST_URI};

    my $code;
    my $content;
    my $content_type;
    # 0 - if cached
    my $cfile = "data/origin/search.cpan.org/" . uri_escape($env->{REQUEST_URI}) . ".new";
    if (-e($cfile) && (time - (stat($cfile))[9] < $config->{cache_timeout}+int(rand($config->{cache_timeout_rand})))) {
        my $rcontent = cat_file($cfile);
        $content = $$rcontent;
        $content_type = "text/html;charset=utf-8";
        $code = 200;
        ### cached : $url
    } else {
        # 1 - fetch from remote
        my $res = $ua->get($url);
        $content_type = $res->header('Content-Type');
        $content = $res->content;
        $code = $res->code;
        ### no cache: $url
        if ($code == 200 && $content_type =~ m{text/}i) {
            open my $fh, ">", $cfile or die $!;
            print $fh $content;
            close $fh;
        }
    }
    
    # 2 - if .pod or .pm, modify content
    if ($code == 200 && $url =~ m{/lib/(.+)\.p(?:m|od)$}) {
        my $module = $1;
        $module =~ s{/}{-}g;
        my $tfile = 'data/trans/cpan/' . $module . ".old";
        ### translate file path: $tfile
        # 2.1 - if translation exists
        if (-e $tfile) {
            ### translate file exist: $tfile
            my $html;
            $pod_parser->output_string(\$html);
            $pod_parser->parse_file($tfile);
            $html = '<div class="pod">' . $html . "</div>";
            $content_type = "text/html;charset=utf-8";
            $content =~ s{^(.*)<div class="?pod"?>.*(<div class="?footer"?>.*)$}{$1$html$2}s;
            #$content = $html;
        }
    }

    # 3 - output
    return [$code, ['Content-Type' => $content_type, 'Content-Length' => length($content)], [$content]];
}

sub {
    my $env = shift;

    # point wiki to homepage
    $env->{'HTTP_HOST'} =~ s/wiki\.perlchina\.org/www.perlchina.org/;
    
    if ($env->{'REQUEST_URI'} =~ m{^/360buy-union\.txt$}) {
        return [200, ['Content-Type' => 'text/plain', 'Content-Length', 36], ['8deabf7d-f2cf-4a95-8119-34c4044391da']];
    } elsif ($env->{'HTTP_HOST'} =~ m{^cpan\.perlchina\.org}) {
        return get_cpan($env);
    } else {
        return get_content($env);
    }
}
