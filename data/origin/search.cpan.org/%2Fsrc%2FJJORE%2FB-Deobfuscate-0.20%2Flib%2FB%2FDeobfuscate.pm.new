package B::Deobfuscate;
use strict;
use warnings;
use vars qw( @ISA $VERSION );
use B qw( main_cv main_root main_start );
use B::Deparse;

BEGIN {
    @ISA     = 'B::Deparse';
    $VERSION = '0.20';

    for my $func (qw( begin_av init_av check_av end_av )) {

        ## no critic
        no strict 'refs';
        if ( defined &{"B::$func"} ) {
            B->import($func);
        }
        else {

           # If I couldn't create it, I'll just declare it to keep lint happy.
            eval "sub $func;";
        }
    }

    # B::perlstring was added in 5.8.0
    if ( defined &B::perlstring ) {
        B->import('perlstring');
    }
    else {
        *perlstring = sub { '"' . quotemeta( shift @_ ) . '"' };
    }

}
use B::Keywords qw( @Barewords @Symbols );

use Carp 'confess';
use IO::Handle ();
use YAML qw( LoadFile Dump );

# use Data::Postponed 'postpone_forever';
sub postpone_forever { return shift @_ }

sub load_keywords {
    my $self = shift @_;
    my $p    = $self->{ +__PACKAGE__ };

    return $p->{keywords} = {
        map { $_, undef } @Barewords,

        # Snip the sigils.
        map { substr $_, 1 } @Symbols
    };
}

sub load_unknown_dict {
    my $self = shift @_;
    my $p    = $self->{ +__PACKAGE__ };

    my $dict_data;

    # slurp the entire dictionary at once
    if ( defined( my $dict_file = $p->{unknown_dict_file} ) ) {
        open my $fh, '<', $dict_file
            or confess "Cannot open dictionary $dict_file: $!";
        local $/;    ## no critic
        $dict_data = [<$fh>];
    }
    else {
    LOAD_DICTIONARY_MODULE:
        for my $module ( $p->{unknown_dict_module}, 'PGPHashKeywords',
            'Flowers' )
        {
            next if not defined $module;
            eval "require B::Deobfuscate::Dict::$module";    ## no critic
            next if $@;

            no strict 'refs';                                ## no critic
            $dict_data = ${"B::Deobfuscate::Dict::$module"};
            last LOAD_DICTIONARY_MODULE;
        }
    }

    unless ($dict_data) {
        confess "The symbol dictionary was empty!";
    }

    my $k = $self->load_keywords;

    $p->{unknown_dict_data} = [
        sort { length $a <=> length $b or $a cmp $b }
            grep { not( /\W/ or exists $k->{$_} ) }
            split /\n/,
        $dict_data
    ];

    unless ( scalar @{ $p->{'unknown_dict_data'} } ) {
        confess "The symbol dictionary is empty!";
    }

    return;
}

sub next_short_dict_symbol {
    my $self = shift @_;
    my $p    = $self->{ +__PACKAGE__ };

    my $sym = shift @{ $p->{unknown_dict_data} };
    push @{ $p->{used_symbols} }, $sym;

    unless ($sym) {
        confess "The symbol dictionary has run out and is now empty";
    }

    return $sym;
}

sub next_long_dict_symbol {
    my $self = shift @_;
    my $p    = $self->{ +__PACKAGE__ };

    my $sym = pop @{ $p->{unknown_dict_data} };
    push @{ $p->{used_symbols} }, $sym;

    unless ($sym) {
        confess "The symbol dictionary has run out and is now empty";
    }

    return $sym;
}

sub load_user_config {
    my $self        = shift @_;
    my $p           = $self->{ +__PACKAGE__ };
    my $config_file = $p->{user_config};

    return unless $config_file;

    unless ( -f $config_file ) {
        confess "Configuration file $config_file doesn't exist";
    }

    my $config = ( LoadFile($config_file) )[0];
    $p->{globals_to_ignore} = $config->{globals_to_ignore};
    $p->{pad_symbols}       = $config->{lexicals};
    $p->{gv_symbols}        = $config->{globals};
    if ( $config->{dictionary} ) {
        $p->{unknown_dict_file} = $config->{dictionary};
    }
    if ( $config->{global_regex} ) {
        $p->{global_regex} = qr/$config->{global_regex}/;
    }

    # Symbols that are listed with an undef value actually
    # just aren't renamed at all.
    for my $symt_nym (qw/pad gv/) {
        my $symt = $p->{ $symt_nym . "_symbols" };
        for my $symt_key ( keys %$symt ) {
            if ( not defined $symt->{$symt_key} ) {
                $symt->{$symt_key} = $symt_key;
            }
        }
    }

    return;
}

sub gv_should_be_renamed {
    my ( $self, $sigil, $name ) = @_;
    my $p = $self->{ +__PACKAGE__ };
    my $k = $p->{keywords};

    confess("Undefined sigil") unless defined $sigil;
    confess("Undefined name")  unless defined $name;

# Bug 24334: $1 gets passed in w/o a sigil. Dunno why. That's wrong and broke the previous version of
# the regexp which read m{^\$\d+\z}

    # Ignore keywords.
    return
        if exists $k->{$name}
        or "$sigil$name" =~ m{^\$?\d+\z};

    if ( exists $p->{gv_symbols}{$name}
        or $name =~ $p->{gv_match} )
    {
        return 1;
    }
    return;
}

sub rename_pad {
    my ( $self, $name ) = @_;
    my $p = $self->{ +__PACKAGE__ };

    my ($sigil) = $name =~ m{^(\W+)}
        or confess "Invalid pad variable name $name";

    my $dict = $p->{pad_symbols};
    return $dict->{$name} if $dict->{$name};

    #    $dict->{$name} = $name;
    $dict->{$name} = postpone_forever $sigil . $self->next_short_dict_symbol;

    unless ( $dict->{$name} ) {
        confess "The suggested name for the lexical variable $name is empty";
    }
    return $dict->{$name};
}

sub lookup_sigil {
    my $rv = shift @_;

    return $rv =~ /(?:gv|pad|rv2)sv\z/ ? '$'
        : $rv =~ /(?:gvav|padav|av2arylen|rv2av|aelemfast|aelem|aslice)\z/
        ? '@'
        : $rv =~ /(?:padhv|rv2hv|helem|hslice)\z/ ? '%'
        : $rv =~ /rv2cv\z/                        ? '&'
        : $rv =~ /(?:gv|gelem|rv2gv)\z/           ? ''
        :

        # Nothing valid;
        ();
}

sub rename_gv {
    my ( $self, $name ) = @_;
    my $p = $self->{ +__PACKAGE__ };

    my $sigil_debug = '';
    my $sigil;
FIND_SIGIL: {
        for ( my $cx = 0; not defined $sigil; ++$cx ) {
            my ( undef, undef, undef, $rv ) = caller $cx;
            if ( not $rv ) {
                confess
                    "No sigil could be found. Please report the following text:\n$sigil_debug\n";
            }

            $sigil = lookup_sigil($rv);

            $sigil_debug .= "$cx = $rv\n";
        }
    }

    unless ( defined $sigil ) {
        confess
            "No sigil could be found. Please report the following text:\n$sigil_debug\n";
    }

    return $name unless $self->gv_should_be_renamed( $sigil, $name );

    my $dict = $p->{gv_symbols};

    my $sname = "$sigil$name";
    return $dict->{$sname} if exists $dict->{$sname};
    $dict->{$sname} = postpone_forever $self->next_long_dict_symbol;

    unless ( $dict->{$sname} ) {
        confess "$sname could not be renamed.";
    }

    return $dict->{$sname};
}

## OVERRIDE METHODS FROM B::Deparse

sub new {
    my $class = shift @_;
    my $self  = $class->SUPER::new(@_);
    my $p     = $self->{ +__PACKAGE__ } = {};
    $p->{unknown_dict_file}   = undef;
    $p->{unknown_dict_module} = undef;
    $p->{unknown_dict_data}   = undef;
    $p->{user_config}         = undef;
    $p->{gv_match}            = qw/^[[:lower:][:digit:]_]+\z/;
    $p->{pad_symbols}         = {};
    $p->{gv_symbols}          = {};
    $p->{output_yaml}         = 0;
    $p->{output_fh}           = \*STDOUT;

    while ( my $arg = shift @_ ) {
        ## no critic
        if ( $arg =~ m{^-d([^,]+)} ) {
            $p->{unknown_dict_file} = $1;
        }
        elsif ( $arg =~ m{^-D([^,]+)} ) {
            $p->{unknown_dict_module} = $1;
        }
        elsif ( $arg =~ m{^-c([^,]+)} ) {
            $p->{user_config} = $1;
        }
        elsif ( $arg =~ m{^-m/([^/]+)/} ) {
            $p->{gv_match} = $1;
        }
        elsif ( $arg =~ m{^-y} ) {
            $p->{output_yaml} = 1;
        }
    }

    $self->load_user_config;
    $self->load_unknown_dict;

    return $self;
}

sub compile {    ## no critic Complex
    my (@args) = @_;

    return sub {
        my $source = '';
        my $self   = __PACKAGE__->new(@args);

        # First deparse command-line args
        if ( defined $^I ) {    # deparse -i
            $source .= q(BEGIN { $^I = ) . perlstring($^I) . qq(; }\n);
        }
        if ($^W) {              # deparse -w
            $source .= qq(BEGIN { \$^W = $^W; }\n);
        }
        ## no critic PackageVar
        if ( $/ ne "\n" or defined $O::savebackslash ) {    # deparse -l -0
            my $fs = perlstring($/) || 'undef';
            my $bs = perlstring($O::savebackslash) || 'undef';
            $source .= qq(BEGIN { \$/ = $fs; \$\\ = $bs; }\n);
        }

        # I need to do things differently depending on the perl
        # version.
        if ( $] >= 5.008 ) {
            if ( defined &begin_av
                and begin_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for begin_av->ARRAY;
            }
            if ( defined &check_av
                and check_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for check_av->ARRAY;
            }
            if ( defined &init_av
                and init_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for init_av->ARRAY;
            }
            if ( defined &end_av
                and end_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for end_av->ARRAY;
            }

            $self->stash_subs;
            $self->{curcv}    = main_cv;
            $self->{curcvlex} = undef;
        }
        else {

            # 5.6.x
            $self->stash_subs('main');
            $self->{curcv} = main_cv;
            $self->walk_sub( main_cv, main_start );
        }

        $source .= join "\n", $self->print_protos;
        @{ $self->{subs_todo} }
            = sort { $a->[0] <=> $b->[0] } @{ $self->{subs_todo} };
        $source .= join "\n", $self->indent( $self->deparse( main_root, 0 ) ),
            "\n"
            unless B::Deparse::null main_root;
        my @text;
        while ( scalar @{ $self->{subs_todo} } ) {
            push @text, $self->next_todo;
        }
        $source .= join "\n", $self->indent( join "", @text ), "\n"
            if @text;

        # Print __DATA__ section, if necessary
        my $laststash
            = defined $self->{curcop}
            ? $self->{curcop}->stash->NAME
            : $self->{curstash};
        {
            ## no critic
            no strict 'refs';
            ## use critic
            if ( defined *{ $laststash . "::DATA" } ) {
                if ( eof *{ $laststash . "::DATA" } ) {

                    # I think this only happens when using B::Deobfuscate
                    # on itself.
                    {
                        local $/ = "__DATA__\n";
                        seek *{ $laststash . "::DATA" }, 0, 0;
                        readline *{ $laststash . "::DATA" };
                    }
                }

                $source .= "__DATA__\n";
                $source .= join '', readline *{ $laststash . "::DATA" };
            }
        }

        my $p    = $self->{ +__PACKAGE__ };
        my %dump = (
            lexicals     => $p->{pad_symbols},
            globals      => $p->{gv_symbols},
            dictionary   => $p->{unknown_dict_file},
            global_regex => $p->{gv_match}
        );

        if ( $p->{output_yaml} ) {
            $p->{output_fh}->print( Dump( \%dump, $source ) );
        }
        else {
            $p->{output_fh}->print($source);
        }

        return;
    };
}

sub padname {
    my $self    = shift @_;
    my $padname = $self->SUPER::padname(@_);

    return $self->rename_pad($padname);
}

sub gv_name {
    my $self    = shift @_;
    my $gv_name = $self->SUPER::gv_name(@_);

    return $self->rename_gv($gv_name);
}

# BEGIN {
#     ## no critic
#     no strict 'refs';
#     for my $sub ( grep defined &$_, keys %B::Deobfuscate:: ) {
#         my $orig = \&$sub;
#         *$sub = sub {
#             print "$sub\n";
#             &$orig;
#         };
#     }
# }

1;

## Local Variables:
## perl-lint-bin: "/home/josh/bin/perl/5.9.4/bin/perl5.9.4"
## eval: (setenv "/home/josh/src/B-Deobfuscate/lib" "PERL5LIB")
## End:
