# Sets in FluidDB are collections of strings.
#
# I doubted whether this could be better called SetOfStrings, to be able to
# handle SetOfIntegers if such type is added to FluidDB in the future. It was
# called that way in fact during development, but finally the YAGNI rule won.
# In particular the user-facing "set" alias sounds better than "set"
# as of this version of the FluidDB API.
#
# If FluidDB ever adds more set types "set" could be deprecated but still be
# interpreted as set of strings to be backwards compatible for a while. The
# public interface would be extended as needed.
package Net::FluidDB::Value::Set;
use Moose;
extends 'Net::FluidDB::Value::Native';

sub to_json {
    my $self = shift;
    my @strings = map $self->json->encode("$_"), @{$self->value};
    '[' . join(',', @strings) . ']'
}

sub is_set {
    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Value::Set - FluidDB set values

=head1 SYNOPSIS

 $value = $object->value("fxn/tags");
 
=head1 DESCRIPTION

C<Net::FluidDB::Value::Set> models FluidDB set values.

FluidDB has a type "set of strings" that we model as arrayref of strings.
Take into account, however, that order is not relevant, because they have
set semantics. In particular you may tag with a given collection and fetch
the same collection later in a different order.

You will rarely need to construct one directly. Tagging objects
understands the alias 'set' to allow tagging with ordinary scalars.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Value::Set> is a subclass of L<Net::FluidDB::Value::Native>.

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
