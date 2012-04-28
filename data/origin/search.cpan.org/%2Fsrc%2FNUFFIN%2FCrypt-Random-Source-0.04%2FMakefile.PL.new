#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile(
	NAME         => 'Crypt::Random::Source',
	VERSION_FROM => 'lib/Crypt/Random/Source.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Test::Exception' => 0,
		'Mouse' => '0.04', # lazy_build
		'namespace::clean' => '0.08',
		'Module::Find' => 0,
		'Sub::Exporter' => 0,
	},
);

