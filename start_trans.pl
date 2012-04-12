use strict;
use warnings;

use Smart::Comments "###";
use File::Copy qw(cp);


for my $file (@ARGV) {
    (print "skip ". $file . "\n" and next) unless $file =~ m{\borigin/[^/]+/[^/]+\.new$};
    ### $file
    my $file2 = $file;
    $file2 =~ s{\.new$}{.old};
    ### $file2
    cp $file, $file2;
    my $file3 = $file2;
    $file3 =~ s{\borigin\b}{trans};
    ### $file3
    my $path = $file3;
    $path =~ s{/[^/]+$}{};
    mkdir $path;
    cp $file, $file3;
}
