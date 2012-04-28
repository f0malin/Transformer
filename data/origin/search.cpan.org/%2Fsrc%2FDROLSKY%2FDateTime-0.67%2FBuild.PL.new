
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'ExtUtils::CBuilder' => '0',
    'Module::Build' => '0.3601',
    'Pod::Man' => '1.14',
    'Test::Exception' => '0',
    'Test::More' => '0.88'
  },
  'c_source' => 'c',
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'A date and time object',
  'dist_author' => [
    'Dave Rolsky <autarch@urth.org>'
  ],
  'dist_name' => 'DateTime',
  'dist_version' => '0.67',
  'license' => 'artistic_2',
  'module_name' => 'DateTime',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'DateTime::Locale' => '0.41',
    'DateTime::TimeZone' => '1.09',
    'Math::Round' => '0',
    'Params::Validate' => '0.76',
    'Scalar::Util' => '0',
    'Time::Local' => '1.04',
    'perl' => 'v5.8.1'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

if ( grep { $_ eq '--pp' } @ARGV ) {
    $build->build_elements(
        [ grep { $_ ne 'xs' } @{ $build->build_elements() } ] );
}

$build->create_build_script;
