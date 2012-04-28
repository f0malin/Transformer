
use inc::Module::Install;

# Define metadata
name         'MySQL-Slurp';
perl_version '5.008';
all_from     'lib/MySQL/Slurp.pm';

# Specific dependencies
requires 'Moose'                    => 0.51; 
requires 'MooseX::GlobRef::Object'  => 0.0203;
# requires 'File::Path'             => 2.07;
requires 'File::Temp'               => 0.21;
requires 'Carp'                     => 0;
requires 'List::MoreUtils'          => 0;
requires 'Mknod'                    => 0;
requires 'IO::File'                 => 0.31 ; 
requires 'DBI'                      => 1.50 ;
requires 'DBD::mysql'               => 3.0008 ;
requires 'self';

requires_external_bin 'mysqlimport';
requires_external_bin 'mysql';

test_requires  'Test::More' => '0.42';
# no_index       'directory'  => 'demos';
install_script 'script/mysqlslurp';

WriteAll;
