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

our %FULL_GET_FLAGS = (
    description => 1
);

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
    
    $self->fdb->post(
        path       => $self->abs_path('tags', $self->path_of_namespace),
        headers    => $self->fdb->headers_for_json,
        payload    => $payload,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            $self->_set_object_id($h->{id});            
        }
    );
}

sub get {
    my ($class, $fdb, $path, %opts) = @_;

    $opts{returnDescription} = 1 if delete $opts{description};
    $fdb->get(
        path       => $class->abs_path('tags', $path),
        query      => \%opts,
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            my $t = $class->new(fdb => $fdb, path => $path, %$h);
            $t->_set_object_id($h->{id});
            $t;            
        }
    );
}

sub delete {
    my $self = shift;

    $self->fdb->delete(path => $self->abs_path('tags', $self->path));
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
