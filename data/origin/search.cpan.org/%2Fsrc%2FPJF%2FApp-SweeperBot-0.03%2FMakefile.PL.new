use inc::Module::Install;

name     'App-SweeperBot';
all_from 'lib/App/SweeperBot.pm';
author   'Paul Fenwick <pjf@cpan.org>';

requires 'Win32::Screenshot';
requires 'Win32::GuiTest';

test_requires  'Test::More';
build_requires 'IPC::System::Simple';	# For MakeExe

WriteAll;

