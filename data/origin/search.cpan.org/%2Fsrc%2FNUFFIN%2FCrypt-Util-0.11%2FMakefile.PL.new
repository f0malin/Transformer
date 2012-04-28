#!/usr/bin/perl -w

use strict;

use inc::Module::Install 0.91;

name 'Crypt-Util';

perl_version '5.008';

requires 'Moose'                 => '0.92';
requires 'Digest'                => 0;
requires 'Sub::Exporter'         => 0;
requires 'Storable'              => 0;
requires 'Data::GUID'            => 0;
requires 'namespace::clean'      => '0.08';

build_requires 'Test::More'      => 0;
build_requires 'Test::use::ok'   => 0;
build_requires 'Test::Exception' => 0;

recommends 'MIME::Base64'          => 0;
recommends 'MIME::Base64::URLSafe' => 0;
recommends 'MIME::Base32'          => 0;
recommends 'URI::Escape'           => 0;

recommends 'Crypt::CFB' => 0; # stream ciphers
recommends 'Crypt::CBC' => 0; # block ciphers

recommends 'Crypt::EAX' => '0.04'; # AEAD mode

recommends 'Crypt::Rijndael' => 0; # AES
recommends 'Crypt::Serpent'  => 0; # AES finalist
recommends 'Crypt::Twofish'  => 0; # AES finalist
recommends 'Crypt::RC6'      => 0; # AES finalist
recommends 'Crypt::Blowfish' => 0; # still widely in use
recommends 'Crypt::DES'      => 0; # still widely in use

# Digest::MultiHash requires SHA-1
# Crypt::Utils requires SHA-512 for key munging
unless ( eval { require Digest::SHA } or eval { require Digest::SHA2 } ) {
	# PurePerl will do (Digest::MoreFallbacks)
	unless ( eval { require Digest::SHA::PurePerl } ) {
		requires "Digest::SHA::PurePerl" => 0
	}

	# But for performance Digest::SHA is preferred
	recommends 'Digest::SHA' => 0;
}

recommends 'Crypt::RIPEMD160'  => 0; # it's hip
recommends 'Digest::Whirlpool' => 0; # it's happenning
recommends 'Digest::MD5'       => 0; # it's still alive =(

recommends "Digest::HMAC" => 0;
recommends "Digest::CMAC" => 0;

license "MIT";

all_from 'lib/Crypt/Util.pm';

sign;

WriteAll;



