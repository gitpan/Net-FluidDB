package Net::FluidDB::Object;
use Moose;
extends 'Net::FluidDB::Resource';

use JSON::XS;
use Net::FluidDB::Value;

has about     => (is => 'rw', isa => 'Str', predicate => 'has_about');
has tag_paths => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_tag_paths', default => sub { [] });

sub _build_object {
    my $self = shift;
    $self;
}

sub create {
    my $self = shift;

    my $payload = encode_json($self->has_about ? {about => $self->about} : {});
    my $response = $self->fdb->post(
        path    => '/objects',
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
    my ($class, $fdb, $id, %opts) = @_;
    
    $opts{showAbout} = 1 if delete $opts{about};
    my $response = $fdb->get(
        path    => "/objects/$id",
        query   => \%opts,
        headers => $fdb->accept_header_for_json
    );

    if ($response->is_success) {
        my $h = decode_json($response->content);
        my $o = $class->new(fdb => $fdb, %$h);
        $o->_set_id($id);
        $o->_set_tag_paths($h->{tagPaths});
        $o;
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

sub get_by_about {
    my ($class, $fdb, $about) = @_;
    # TODO: implement it
}

sub tag {
    my ($self, $tag_or_tag_path, @rest) = @_;

    my $tag_path = $self->get_tag_path_from_tag_or_tag_path($tag_or_tag_path);
    my $payload;

    if (@rest == 0) {
        # TODO: tagging with no value
    } elsif (@rest == 1) {
        my $value = shift @rest;
        if (ref($value) && ref($value) ne 'ARRAY') {
            $payload = $value->as_json;
        } else {
            $payload = Net::FluidDB::Value->new(value => $value)->as_json;
        }
    } else {
        my %opts = @rest;
        # TODO: supported keys are file, format, etc. explore this interface
    }
    
    my $response = $self->fdb->put(
        path    => join('/', '/objects', $self->id, $tag_path),
        query   => {format => 'json'},
        headers => $self->fdb->content_type_header_for_json,
        payload => $payload
    );

    if ($response->is_success) {
        1;
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

sub value {
    my ($self, $tag_or_tag_path, @rest) = @_;
    
    my $tag_path = $self->get_tag_path_from_tag_or_tag_path($tag_or_tag_path);
    my $response = $self->fdb->get(
        path    => join('/', '/objects', $self->id, $tag_path),
        query   => {format => 'json'},
        headers => $self->fdb->accept_header_for_json,
    );
    
    if ($response->is_success) {
        my $h = decode_json($response->content);
        my $v = Net::FluidDB::Value->new(%$h);
        $v->has_value_encoding || $v->has_value_type ? $v : $v->value;
    } else {
        print STDERR $response->content, "\n";
        0;
    }    
}

sub get_tag_path_from_tag_or_tag_path {
    my ($self, $tag_or_tag_path) = @_;
    ref($tag_or_tag_path) ? $tag_or_tag_path->path : $tag_or_tag_path;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
