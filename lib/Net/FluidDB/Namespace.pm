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

    my $path = '/namespaces';
    my $path_of_parent = $self->path_of_parent;
    $path .= "/$path_of_parent" if $path_of_parent ne "";
    my $payload = encode_json({description => $self->description, name => $self->name});
    my $response = $self->fdb->post(
        path    => $path,
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

    foreach my $key (qw(description namespaces tags)) {
        $opts{"return\u$key"} = 1 if delete $opts{$key};    
    }
    my $response = $fdb->get(
        path    => "/namespaces/$path",
        query   => \%opts,
        headers => $fdb->accept_header_for_json
    );

    if ($response->is_success) {
        my $h = decode_json($response->content);
        my $ns = $class->new(fdb => $fdb, path => $path, %$h);
        $ns->_set_namespace_names($h->{namespaceNames}) if $opts{returnNamespaces};
        $ns->_set_tag_names($h->{tagNames}) if $opts{returnTags};
        $ns;
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

# Normal usage is to set description and path of self.
sub update {
    my $self = shift;

    my $payload = encode_json({description => $self->description});
    my $response = $self->fdb->put(
        path    => '/namespaces/' . $self->path,
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

sub delete {
    my $self = shift;
    my $response = $self->fdb->delete(path => '/namespaces/' . $self->path);
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
