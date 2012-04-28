#!perl -w

use Test::More;
plan skip_all => qq["binmode FH, ':utf8'" needs Perl >= 5.8]
    unless $^V >= 5.008;
plan tests => 3;
use IPC::Run3;
use strict;

my ( $in, $out, $err );

# Perl code to generate a Unicode string of
# LATIN1 SMALL LETTERS A, O, U WITH DIAERESIS
my $generate_unicode = qq[pack("U3", 0xe4, 0xf6, 0xfc)];
# bytes encoding the above in UTF8
my @expected_bytes = ( 0xc3, 0xa4, 0xc3, 0xb6, 0xc3, 0xbc );

# read as UTF8
( $in, $out, $err ) = ();
run3 [ $^X, "-e", "binmode STDOUT, ':utf8'; print $generate_unicode" ], 
    \undef, \$out, \undef, { binmode_stdout => ':utf8' };
is length($out), 3, 			"read Unicode string of 3 characters";
my @got_bytes;
{ use bytes; @got_bytes = unpack('C*', $out); }
is "@got_bytes", "@expected_bytes",	"compare raw bytes read from command";

# write as UTF8
# NOTE: extra careful here, only write "Unicode safe" stuff in the child perl; 
# e.g. Perl 5.8.0 might have ":utf8" implicitly turned on for STDOUT when 
# invoked in a UTF8 locale (resulting in 12 bytes read into $out when simply
# copying STDIN to STDOUT)
( $in, $out, $err ) = ();
$in = eval $generate_unicode;
run3 [ $^X, "-e", "binmode STDIN, ':raw'; print join(' ', unpack('C*', <>))" ],
    \$in, \$out, \undef, { binmode_stdin => ':utf8' };
is $out, "@expected_bytes",		"compare raw bytes written to command";


