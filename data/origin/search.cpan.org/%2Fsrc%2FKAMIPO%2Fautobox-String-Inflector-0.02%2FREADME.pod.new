package autobox::String::Inflector;

use strict;
use warnings;
our $VERSION = '0.02';

use base qw(autobox);

sub import {
    shift->SUPER::import(STRING => 'autobox::String::Inflector::Impl', @_);
}

package # hide from pause
    autobox::String::Inflector::Impl;

use String::CamelCase qw(camelize decamelize);
use Lingua::EN::Inflect::Number ();

*pluralize = \&Lingua::EN::Inflect::Number::to_PL;

sub singularize {
    local $_ = shift;
    return $_ if s/(alias|status)es$/$1/i;
    return Lingua::EN::Inflect::Number::to_S($_);
}

1;
__END__

=head1 NAME

autobox::String::Inflector - Rails like String Inflector

=head1 SYNOPSIS

  use autobox::String::Inflector;

  print 'users'->singularize->camelize; # User

  print 'Entry'->decamelize->pluralize; # entries

=head1 DESCRIPTION

autobox::String::Inflector is Rails like String Inflector.

=head1 AUTHOR

Ryuta Kamizono E<lt>kamipo@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
