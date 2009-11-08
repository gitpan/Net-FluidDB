package Net::FluidDB::User;
use Moose;
extends 'Net::FluidDB::Base';

with 'Net::FluidDB::HasObject';

has name     => (is => 'ro', isa => 'Str');
has username => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fdb, $username) = @_;

    $fdb->get(
        path       => $class->abs_path('users', $username),
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            my $user = $class->new(fdb => $fdb, username => $username, %$h);
            $user->_set_object_id($h->{id});
            $user;
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::User - FluidDB users

=head1 SYNOPSIS

 use Net::FluidDB::User;

 $user = Net::FluidDB::User->get($fdb, $username);
 $user->name;
 
=head1 DESCRIPTION

Net::FluidDB::User models FluidDB users.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::User> is a subclass of L<Net::FluidDB::Base>.

=head2 Roles

C<Net::FluidDB::User> consumes the role L<Net::FluidDB::HasObject>.

=head2 Class methods

=over

=item Net::FluidDB::User->get($fdb, $username)

Retrieves the user with username C<$username> from FluidDB.

C<Net::FluidDB> provides a convenience shortcut for this method.

=back

=head2 Instance Methods

=over

=item $user->username

Returns the username of the user.

=item $user->name

Returns the name of the user.

=back

=head1 FLUIDDB DOCUMENTATION

=over

=item FluidDB high-level description

L<http://doc.fluidinfo.com/fluidDB/users.html>

=item FluidDB API specification

L<http://api.fluidinfo.com/fluidDB/api/*/users/*>

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
