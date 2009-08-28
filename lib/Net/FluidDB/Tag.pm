package Net::FluidDB::Tag;
use Moose;
extends 'Net::FluidDB::Resource';

use Net::FluidDB::Namespace;
use JSON::XS;

has namespace   => (is => 'rw', isa => 'Net::FluidDB::Namespace', lazy_build => 1);
has description => (is => 'rw', isa => 'Str');
has indexed     => (is => 'rw', isa => 'Bool');
has name        => (is => 'rw', isa => 'Str', lazy_build => 1);
has path        => (is => 'rw', isa => 'Str', lazy_build => 1);

sub _build_namespace {
    # TODO: add croaks for dependencies
    my $self = shift;
    Net::FluidDB::Namespace->get(
        $self->fdb,
        $self->path_of_namespace,
        %Net::FluidDB::Namespace::FULL_GET_FLAGS
    );
}

sub _build_name {
    # TODO: add croaks for dependencies
    my $self = shift;
    my @names = split "/", $self->path;
    $names[-1];
}

sub _build_path {
    # TODO: add croaks for dependencies
    my $self = shift;
    $self->namespace->path . '/' . $self->name;
}

sub path_of_namespace {
   my $self = shift;
   my @names = split "/", $self->path;
   join "/", @names[0 .. $#names-1];
}

sub create {
    my $self = shift;
    
    my $payload = encode_json({
        description => $self->description,
        indexed     => $self->indexed,
        name        => $self->name
    });
    
    my $response = $self->fdb->post(
        path    => '/tags/' . $self->path_of_namespace,
        headers => $self->fdb->headers_for_json,
        payload => $payload
    );
    
    if ($response->is_success) {
        my $h = decode_json($response->content);
        $self->_set_id($h->{id});
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

sub get {
    my ($class, $fdb, $path, %opts) = @_;

    $opts{returnDescription} = 1 if delete $opts{description};
    my $response = $fdb->get(
        path    => "/tags/$path",
        query   => \%opts,
        headers => $fdb->accept_header_for_json
    );

    if ($response->is_success) {
        my $h = decode_json($response->content);
        $class->new(fdb => $fdb, path => $path, %$h);
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

sub delete {
    my $self = shift;

    my $response = $self->fdb->delete(path => '/tags/' . $self->path);
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
