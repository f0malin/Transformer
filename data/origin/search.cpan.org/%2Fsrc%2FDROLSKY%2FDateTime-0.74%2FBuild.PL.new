
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Cwd" => 0,
    "Module::Build" => "0.3601",
    "Storable" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.88",
    "utf8" => 0
  },
  "c_source" => "c",
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A date and time object",
  "dist_author" => [
    "Dave Rolsky <autarch\@urth.org>"
  ],
  "dist_name" => "DateTime",
  "dist_version" => "0.74",
  "license" => "artistic_2",
  "module_name" => "DateTime",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "DateTime::Locale" => "0.41",
    "DateTime::TimeZone" => "1.09",
    "Math::Round" => 0,
    "Params::Validate" => "0.76",
    "Scalar::Util" => 0,
    "Time::Local" => "1.04",
    "XSLoader" => 0,
    "base" => 0,
    "constant" => 0,
    "integer" => 0,
    "overload" => 0,
    "perl" => "5.008001",
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

my $skip_xs;
if ( grep { $_ eq '--pp' } @ARGV ) {
    $skip_xs = 1;
}
elsif ( ! $build->have_c_compiler() ) {
    $skip_xs = 1;
}

if ($skip_xs) {
    $build->build_elements(
        [ grep { $_ ne 'xs' } @{ $build->build_elements() } ] );
}
$build->create_build_script;
