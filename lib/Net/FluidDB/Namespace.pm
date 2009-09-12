package Net::FluidDB::Namespace;
use Moose;
extends 'Net::FluidDB::Resource';

use JSON::XS;

# description is required to create a namespace in FluidDB
# but GET may not retrieve it, depending on a flag
has parent          => (is => 'rw', isa => 'Maybe[Net::FluidDB::Namespace]', lazy_build => 1); 
has description     => (is => 'rw', isa => 'Str');
has name            => (is => 'rw', isa => 'Str', lazy_build => 1);
has path            => (is => 'rw', isa => 'Str', lazy_build => 1);
has namespace_names => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_namespace_names');
has tag_names       => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_tag_names');

our %FULL_GET_FLAGS = (
    description => 1,
    namespaces  => 1,
    tags        => 1
);

sub _build_name {
    # TODO: add croaks for dependencies
    my $self = shift;
    my @names = split "/", $self->path;
    $names[-1];
}

sub _build_path {
    # TODO: add croaks for dependencies
    my $self = shift;
    if ($self->parent) {
        $self->parent->path . '/' . $self->name;
    } else {
        $self->name;
    }
}

sub _build_parent {
    # TODO: add croaks for dependencies
    my $self = shift;
    if ($self->path_of_parent ne "") {
        __PACKAGE__->get($self->fdb, $self->path_of_parent, %FULL_GET_FLAGS);
    } else {
        undef;
    }
}

sub path_of_parent {
   my $self = shift;
   my @names = split "/", $self->path;
   join "/", @names[0 .. $#names-1];
}

# Normal usage is to set description and path of self.
sub create {
    my $self = shift;

    my $payload = encode_json({description => $self->description, name => $self->name});
    $self->fdb->post(
        path       => $self->abs_path('namespaces', $self->path_of_parent),
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

    foreach my $key (qw(description namespaces tags)) {
        $opts{"return\u$key"} = 1 if delete $opts{$key};    
    }
    $fdb->get(
        path       => $class->abs_path('namespaces', $path),
        query      => \%opts,
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            my $ns = $class->new(fdb => $fdb, path => $path);
            $ns->_set_object_id($h->{id});
            $ns->description($h->{description})             if $opts{returnDescription};
            $ns->_set_namespace_names($h->{namespaceNames}) if $opts{returnNamespaces};
            $ns->_set_tag_names($h->{tagNames})             if $opts{returnTags};
            $ns;            
        }
    );
}

# Normal usage is to set description and path of self.
sub update {
    my $self = shift;

    my $payload = encode_json({description => $self->description});
    $self->fdb->put(
        path    => $self->abs_path('namespaces', $self->path),
        headers => $self->fdb->headers_for_json,
        payload => $payload
    );
}

sub delete {
    my $self = shift;

    $self->fdb->delete(path => $self->abs_path('namespaces', $self->path));
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
