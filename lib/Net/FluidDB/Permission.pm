package Net::FluidDB::Permission;
use Moose;
extends 'Net::FluidDB::ACL';

use JSON::XS;

has category => (is => 'ro', isa => 'Str');
has path     => (is => 'ro', isa => 'Str');
has action   => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fdb, $category, $path, $action) = @_;

    $fdb->get(
        path       => $class->abs_path('permissions', $category, $path),
        query      => { action => $action },
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            $class->new(
                fdb      => $fdb,
                category => $category,
                path     => $path,
                action   => $action,
                %$h
            );
        }
    );
}

sub update {
    my $self = shift;

    my $payload = encode_json({policy => $self->policy, exceptions => $self->exceptions});
    $self->fdb->put(
        path    => $self->abs_path('permissions', $self->category, $self->path),
        query   => { action => $self->action },
        headers => $self->fdb->headers_for_json,
        payload => $payload
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Policy - FluidDB permissions

=head1 SYNOPSIS

 use Net::FluidDB::Permission;

 # get
 $permission = Net::FluidDB::Permission->get($fdb, $category, $path, $action);
 $permission->policy;
 $permission->exceptions;

 # update
 $permission->policy('closed');
 $permission->exceptions($exceptions);
 $permission->update;

=head1 DESCRIPTION

Net::FluidDB::Permission models FluidDB permissions.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Permission> is a subclass of L<Net::FluidDB::ACL>.

=head2 Class methods

=over

=item Net::FluidDB::Permission->get($fdb, $category, $path, $action)

Retrieves the permission on action C<$action>, for the category C<$category> and path C<$path>.

=back

=head2 Instance Methods

=over

=item $tag->update

Updates the permission in FluidDB.

=item $tag->category

Returns the category the permission is about.

=item $tag->path

Returns the path of the category the permission is about.

=item $tag->action

Returns the action the permission is about.

=back

=head1 FLUIDDB DOCUMENTATION

=over

=item FluidDB high-level description

L<http://doc.fluidinfo.com/fluidDB/permissions.html>

=item FluidDB API documentation

L<http://doc.fluidinfo.com/fluidDB/api/http.html#authentication-and-authorization>

=item FluidDB API specification

L<http://api.fluidinfo.com/fluidDB/api/*/permissions/*>

=back

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

