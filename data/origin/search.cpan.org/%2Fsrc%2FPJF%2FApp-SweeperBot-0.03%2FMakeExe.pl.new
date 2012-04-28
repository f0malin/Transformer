#!/usr/bin/perl -w
use strict;
use lib 'lib';
use IPC::System::Simple qw(run);
require App::SweeperBot;

my $output = q{SweeperBot.exe};
my $input  = q{bin\sweeperbot.pl};

my @dlls = qw(
	CORE_RL_bzlib_
	CORE_RL_jpeg_
	CORE_RL_lcms_
	CORE_RL_magick_
	CORE_RL_tiff_
	CORE_RL_ttf_
	CORE_RL_zlib_
	IM_MOD_RL_rgb_
	IM_MOD_RL_rle_
	X11
);

my @info = (
	qq{FileVersion=$App::SweeperBot::VERSION},
	qq{FileDescription="Play minesweeper automatically"},
	qq{LegalCopyright="May be distributed or modified under the terms of Perl 5"},
);

	

my $magick_path = q{c:\perl\site\lib\auto\Image\Magick};

foreach my $dll (@dlls) {
	-e "$magick_path/$dll.dll" or die "Can't find $magick_path/$dll.dll";
}

run(
	q{pp.bat},'-o', $output, '-I=lib',
	( map { "-l=$magick_path\\$_.dll" } @dlls),
	'-N', join(";",@info),
	qw(-z 9),
	$input
);

