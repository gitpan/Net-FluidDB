package Net::FluidDB::Value::Float;
use Moose;
extends 'Net::FluidDB::Value::Native';

# This serializer tries to send the best representation of the value, and let's
# Perl choose whether that's scientific notation or not.
#
# FluidDB handles integers and floats differently, care in serialisation is needed.
# For example if you tag object X with tag T and serialised value "5", then X won't
# be returned in a query for objects tagged with T with value less than "10.0".
# Reason is FluidDB interprets the type of the value serialised as "5" to be integer,
# and it won't pick it as float unless you serialise it explicitly as such: "5.0".
sub to_json {
    my $self  = shift;
    no warnings; # value may not be a number
    my $float = 0 + $self->value; # ensure we get a number
    my $e     = sprintf "%g", $float;
    index($e, 'e') != -1 ? $e : index($float, '.') != -1 ? "$float" : "$float.0";
}

sub is_float {
    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Value::Float - FluidDB float values

=head1 SYNOPSIS

 $value = $object->value("fxn/height");
 
=head1 DESCRIPTION

C<Net::FluidDB::Value::Float> models FluidDB float values.

You will rarely need to construct one directly. Tagging objects
understands the alias 'float' to allow tagging with ordinary scalars.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Value::Float> is a subclass of L<Net::FluidDB::Value::Native>.

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
