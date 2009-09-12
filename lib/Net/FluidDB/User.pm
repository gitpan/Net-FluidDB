package Net::FluidDB::User;
use Moose;
extends 'Net::FluidDB::Resource';

use JSON::XS;

has name     => (is => 'ro', isa => 'Str');
has username => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fdb, $username) = @_;

    my $response = $fdb->get(
        path       => $class->abs_path('users', $username),
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            my $user = $class->new(fdb => $fdb, username => $username, %$h);
            $user->_set_object_id($h->{id});
            $user;
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
