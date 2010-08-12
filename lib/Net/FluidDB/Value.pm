# This is the root class of all FluidDB value types. The hierarchy splits
# into native types and non native types.
#
# These objects carry transport knowledge as of today. They know their MIME
# type, and they know how they should be travel as payload of HTTP requests.
# This could be internally redesigned in the future, but by now looks like
# a good compromise.
package Net::FluidDB::Value;
use Moose;

has mime_type => (is => 'ro', isa => 'Str');
has value     => (is => 'ro', isa => 'Any');

sub is_native {
    0;
}

sub is_non_native {
    0;
}

sub new_from_mime_type_and_content {
    my ($class, $mime_type, $content) = @_;
    
    # instead of ordinary use(), to play nice with inheritance
    require Net::FluidDB::Value::Native;
    if (Net::FluidDB::Value::Native->is_mime_type($mime_type)) {
        Net::FluidDB::Value::Native->new_from_json($content);
    } else {
        # instead of ordinary use(), to play nice with inheritance
        require Net::FluidDB::Value::NonNative;
        Net::FluidDB::Value::NonNative->new(mime_type => $mime_type, value => $content);
    }
}

sub payload {
    # abstract
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Value - FluidDB values

=head1 SYNOPSIS

 $value = $object->value("fxn/rating");
 
=head1 DESCRIPTION

C<Net::FluidDB::Value> models FluidDB values.

C<Net::FluidDB::Value> is a parent class of L<Net::FluidDB::Value::Native> and
L<Net::FluidDB::Value::NonNative>.

=head1 USAGE

=head2 Instance Methods

=over

=item $value->value

Returns the actual scalar value.

=item $value->mime_type

Returns the MIME type of the value.

=item $value->is_native

Says whether the value is native, see L<Net::FluidDB::Value::Native>.

=item $value->is_non_native

Says whether the value is native, see L<Net::FluidDB::Value::NonNative>.

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
