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

no Moose;
__PACKAGE__->meta->make_immutable;

1;
