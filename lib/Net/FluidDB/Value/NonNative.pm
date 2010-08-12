package Net::FluidDB::Value::NonNative;
use Moose;
extends 'Net::FluidDB::Value';

sub is_non_native {
    1;
}

sub payload {
    shift->value;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Value::NonNative - FluidDB non-native values

=head1 SYNOPSIS

 $value = $object->value("fxn/rating");
 
=head1 DESCRIPTION

C<Net::FluidDB::Value::NonNative> models FluidDB non-native values.

FluidDB non-native values are opaque, think blobs with a MIME type.
You may store and fetch them, but can't use them in searches.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Value::NonNative> is a subclass of L<Net::FluidDB::Value>.

=head2 Instance Methods

=over

=item $value->mime_type

Returns the MIME type of the value.

=back

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
