
use strict;
use 5.006;
use inc::Module::Install;

name        'PAR';
abstract    'Perl Archive Tookit';
all_from    'lib/PAR.pm';

requires    'File::Temp'        => 0.05;
requires    'Compress::Zlib'    => ($^O eq 'MSWin32') ? 1.16 : 1.30;
requires    'Archive::Zip'      => 1.00;
requires    'PAR::Dist'         => 0.32;
requires    'AutoLoader'        => '5.66_02';

if (can_use('Crypt::OpenPGP') or can_run('gpg')) {
    my $has_sha1 = (
        can_use('Digest::SHA1') or
        can_use('Digest::SHA')  or
        can_use('Digest::SHA::PurePerl')
    );

    feature 'Digital signature support',
    recommends
            'Digest',
            ($has_sha1 ? () : (can_cc() ? 'Digest::SHA'
                                        : 'Digest::SHA::PurePerl')),
            'Module::Signature';
}

include_deps        'Test::More';
no_index            directory => 'contrib';
auto_provides;

WriteAll sign => 0;
