use inc::Module::Install;

    name     'DBIx-MyParseX';
    all_from 'lib/DBIx/MyParseX.pm';
    author   'Christopher Brown <ctbrown@cpan.org>';
    license 'gpl';


    build_requires 'Test::More';
    # requires 'Moose' => 0.00;
    requires 'DBIx::MyParse'        => 0;
    requires 'DBIx::MyParse::Query' => 0;
    requires 'DBIx::MyParse::Item'  => 0;
    requires 'List::MoreUtils'      => 0.22;
    requires 'self'                 => 0.15;

    auto_install;

    WriteAll;

