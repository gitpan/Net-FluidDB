package Net::FluidDB::Permission;
use Moose;
extends 'Net::FluidDB::ACL';

use JSON::XS;
use Net::FluidDB::Policy;
use Net::FluidDB::Namespace;
use Net::FluidDB::Tag;

has category => (is => 'ro', isa => 'Str');
has path     => (is => 'ro', isa => 'Str');
has action   => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fdb, $category, $path, $action) = @_;

    my $response = $fdb->get(
        path    => $class->abs_path('permissions', $category, $path),
        query   => { action => $action },
        headers => $fdb->accept_header_for_json
    );
    
    if ($response->is_success) {
        my $h = decode_json($response->content);
        $class->new(fdb => $fdb, category => $category, path => $path, action => $action, %$h);
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

sub update {
    my $self = shift;

    my $payload = encode_json({policy => $self->policy, exceptions => $self->exceptions});
    my $response = $self->fdb->put(
        path    => $self->abs_path('permissions', $self->category, $self->path),
        query   => { action => $self->action },
        headers => $self->fdb->headers_for_json,
        payload => $payload
    );

    if ($response->is_success) {
        1;        
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
