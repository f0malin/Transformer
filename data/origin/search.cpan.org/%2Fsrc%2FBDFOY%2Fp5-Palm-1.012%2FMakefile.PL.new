use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.21";

my @classes = qw( 
	Address Datebook DateTime Mail 
	Memo PDB Raw StdAppInfo ToDo 
	ZirePhoto
	);

WriteMakefile(
    'NAME'			=> 'Palm',
	'ABSTRACT'		=> 'Module for handling PalmOS databases',
    'VERSION_FROM'  => 'lib/Palm.pm',
    'LICENSE'       => 'perl',
    'DISTNAME'		=> 'p5-Palm',	# More descriptive than just "Palm"
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'		=> {
		'Test::More'	=> '0',
		},

	'PM'           => {
		'lib/Palm.pm' => '$(INST_LIBDIR)/Palm.pm',
		map { ( "lib/$_.pm", "\$(INST_LIBDIR)/Palm/$_.pm" ) } @classes
		},

    'EXE_FILES'		=> [ 'examples/pdbdump' ],

	clean  => { FILES    => q|*.bak p5-*| },

);
