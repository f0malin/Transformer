# This Makefile.PL stolen from Params::Validate
#
# The perl/C checking voodoo is stolen from Graham Barr's
# Scalar-List-Utils distribution.

use strict;

use ExtUtils::MakeMaker;
use Config qw(%Config);
use File::Spec;

use vars qw ($no_xs $force_xs);

if ( $] >= 5.009_001 && $] < 5.010_000 ) {
    die "The CPAN module cannot be tested with Perl $]\n".
    	"Please update to the latest bleadperl...";
}

for (@ARGV)
{
    /^--perl_only/ and $no_xs = 1;
    /^--perl-only/ and $no_xs = 1;
    /^--xs/ and $no_xs = 0;
}

map { unlink $_ if -f $_ } <vutil/Makefile*>;

unless (defined $no_xs)
{
    check_for_compiler()
        or no_cc();
}

write_makefile();

sub write_makefile
{
    my %prereq = ( 'Test::More' => 0.45, 'File::Temp' => 0.13 );

    WriteMakefile( VERSION_FROM    => 'lib/version.pm',
                   NAME            => 'version',
                   LICENSE         => 'perl',
                   PREREQ_PM       => \%prereq,
                   CONFIGURE       => \&init,
                   ( $] >= 5.005 ?
                     ( ABSTRACT    => 'Structured version objects',
                       AUTHOR      => 'John Peacock <jpeacock@cpan.org>') :
                     ()
                   ), 
		   ( $] >= 5.009001 && $] < 5.011000 ?
		     ( INSTALLDIRS => 'perl' ) :
		     ()
		   ),
                   PM              => 
                       {'lib/version.pm'  => '$(INST_LIBDIR)/version.pm',
                        'lib/version.pod' => '$(INST_LIBDIR)/version.pod',
                        'lib/version/Internals.pod' =>
			    '$(INST_LIBDIR)/version/Internals.pod'},
                   PL_FILES        => {},
                   C               => [],
                   clean           => { FILES => 'vutil/Makefile.PL' },
                   dist            => {
                       COMPRESS => 'gzip -9f', 
                       SUFFIX => 'gz',
                       PREOP  => (
                          'hg log --style changelog > Changes'
                       ),
                   },

                 );
}

sub init
{
    my $hash = $_[1];

    if ($no_xs) {
        $hash->{'PM'}->{'vperl/vpp.pm'} = '$(INST_LIBDIR)/version/vpp.pm';
    }
    else {
        open MAKEFILE, '>vutil/Makefile.PL';
        while (<DATA>) {
            print MAKEFILE $_;
        }
        close MAKEFILE;
        sleep(1);
        @{ $hash }{ 'DIR' } = ['vutil'];
    }

    return $hash;
}

sub no_cc
{
    $no_xs = 1;
    print <<'EOF';

 I cannot determine if you have a C compiler
 so I will install a perl-only implementation

 You can force installation of the XS version with

    perl Makefile.PL --xs

EOF

}

sub check_for_compiler
{
    print "Testing if you have a C compiler\n";

    eval { require ExtUtils::CBuilder };
    if ($@)
    {
        return _check_for_compiler_manually();
    }
    else
    {
        return _check_for_compiler_with_cbuilder();
    }
}

sub _check_for_compiler_with_cbuilder
{
    my $cb = ExtUtils::CBuilder->new( quiet => 1 );

    return $cb->have_compiler;
}

sub _check_for_compiler_manually
{
    unless ( open F, ">test.c" )
    {
        warn "Cannot write test.c, skipping test compilation and installing pure Perl version.\n";
        return 0;
    }

    print F <<'EOF';
int main() { return 0; }
EOF

    close F or return 0;

    my $cc = $Config{cc};

    my $retval = system( "$cc -c -o test$Config{obj_ext} test.c" );
    map { unlink $_ if -f $_ } ('test.c',"test$Config{obj_ext}");

    return not($retval); # system returns -1
}

__DATA__
#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'version::vxs',
    AUTHOR              => 'John Peacock <jpeacock@cpan.org>',
    VERSION_FROM        => 'lib/version/vxs.pm',
    OBJECT              => q/$(O_FILES)/,
    TYPEMAPS            => ['../lib/version/typemap'],
);
