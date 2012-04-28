#!/usr/bin/perl
use strict;
use inc::Module::Install 1.00;

name            'Module-ScanDeps';
all_from        'lib/Module/ScanDeps.pm';
repository      'http://svn.openfoundry.org/par/Module-ScanDeps/trunk/';

perl_version    '5.008001';
requires        'File::Temp'                => '0';
requires        'File::Spec'                => '0';
requires        'Module::Build::ModuleInfo' => '0';
requires        'version'                   => '0';
build_requires  'Test::More'                => '0';

install_script  'script/scandeps.pl';

no_index        module  => 'Module::ScanDeps::Cache';
no_index        module  => 'Module::ScanDeps::DataFeed';

#sign;
WriteAll;
