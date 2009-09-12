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
