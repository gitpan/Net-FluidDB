package Net::FluidDB::HasObject;
use Moose::Role;

use Net::FluidDB::Object;

has object_id => (is => 'ro', isa => 'Str', writer => '_set_object_id', predicate => 'has_object_id');

has object => (
    is         => 'ro',
    isa        => 'Net::FluidDB::Object',
    lazy_build => 1,
    handles    => [qw(tag value)]
);

sub _build_object {
    # TODO: croak if no ID.
    my $self = shift;
    Net::FluidDB::Object->get_by_id($self->fdb, $self->object_id, about => 1);
}

1;

__END__

=head1 NAME

C<Net::FluidDB::HasObject> - Role for resources that have an object

=head1 SYNOPSIS

 $namespace->object_id;
 $namespace->object;
 
 $user->tag($tag, integer => 0);
 $user->value($tag)

=head1 DESCRIPTION

Net::FluidDB::HasObject is a role consumed by L<Net::FluidDB::Tag>,
L<Net::FluidDB::Namespace>, and L<Net::FluidDB::User>. They have in common
that FluidDB creates an object for them.

=head1 USAGE

=head2 Instance Methods

=over

=item $resource->object_id

The UUID of the object FluidDB created for the resource.

=item $resource->object

The object FluidDB created for the resource. This attribute is lazy loaded.

=item $resource->tag($tag_or_tag_path, $value, %options)

=item $resource->value($tag_or_tag_path)

Convenience methods that proxy the call to the underlying object.
See L<Net::FluidDB::Object>.

=back

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
