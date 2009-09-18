package Net::FluidDB::Object;
use Moose;
extends 'Net::FluidDB::Base';

use JSON::XS;
use Net::FluidDB::Value;

has id        => (is => 'ro', isa => 'Str', writer => '_set_id', predicate => 'has_id');
has about     => (is => 'rw', isa => 'Str', predicate => 'has_about');
has tag_paths => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_tag_paths', default => sub { [] });

sub create {
    my $self = shift;

    my $payload = encode_json($self->has_about ? {about => $self->about} : {});
    $self->fdb->post(
        path       => $self->abs_path('objects'),
        headers    => $self->fdb->headers_for_json,
        payload    => $payload,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);        
            $self->_set_id($h->{id});
        }
    );
}

sub get {
    my ($class, $fdb, $id, %opts) = @_;

    $opts{showAbout} = 1 if delete $opts{about};
    $fdb->get(
        path       => $class->abs_path('objects', $id),
        query      => \%opts,
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            my $o = $class->new(fdb => $fdb, %$h);
            $o->_set_id($id);
            $o->_set_tag_paths($h->{tagPaths});
            $o;            
        }
    );
}

sub get_by_about {
    my ($class, $fdb, $about) = @_;
    # TODO: implement it
}

sub search {
    my ($class, $fdb, $query) = @_;

    my %params = (query => $query);
    $fdb->get(
        path       => '/objects',
        query      => \%params,
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            @{decode_json($response->content)->{ids}};
        }
    );
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
    
    $self->fdb->put(
        path    => $self->abs_path('objects', $self->id, $tag_path),
        query   => {format => 'json'},
        headers => $self->fdb->content_type_header_for_json,
        payload => $payload
    );
}

sub value {
    my ($self, $tag_or_tag_path, @rest) = @_;
    
    my $tag_path = $self->get_tag_path_from_tag_or_tag_path($tag_or_tag_path);
    $self->fdb->get(
        path    => $self->abs_path('objects', $self->id, $tag_path),
        query   => {format => 'json'},
        headers => $self->fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            my $v = Net::FluidDB::Value->new(%$h);
            $v->has_value_encoding || $v->has_value_type ? $v : $v->value;
        }
    );
}

sub get_tag_path_from_tag_or_tag_path {
    my ($self, $tag_or_tag_path) = @_;
    ref($tag_or_tag_path) ? $tag_or_tag_path->path : $tag_or_tag_path;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Object - FluidDB objects

=head1 SYNOPSIS

 use Net::FluidDB::Object;

 # create, with optional about
 $object = Net::FluidDB::Object->new(
     fdb   => $fdb,
     about => $unique_about
 );
 $object->create;
 $object->id; # returns the object's ID in FluidDB 
 
 # get by ID, optionally fetching about
 $object = Net::FluidDB::Object->get($fdb, $object_id, about => 1);

 # search
 @ids = Net::FluidDB::Object->search($fdb, "has fxn/rating");
 
=head1 DESCRIPTION

Net::FluidDB::Object models FluidDB objects.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Object> is a subclass of L<Net::FluidDB::Base>.

=head2 Class methods

=over

=item Net::FluidDB::Object->new(%attrs)

Constructs a new object. The constructor accepts these parameters:

=over

=item fdb (required)

An instance of Net::FluidDB.

=item about (optional)

A string, if any.

=back

This constructor is only useful for creating new objects in FluidDB.
Already existing objects are fetched with C<get>.

=item Net::FluidDB::Object->get($fdb, $id, %opts)

Retrieves the object with ID C<$id> from FluidDB. Options are:

=over

=item about (optional, default false)

Tells C<get> whether you want to get the about attribute of the object.

If about is not fetched C<has_about> will be false even if the object
has an about attribute in FluidDB.

=back

=item Net::FluidDB::Object->search($fdb, $query)

Performs the query C<$query> and returns a (possibly empty) array of strings with
the IDs of the macthing objects.

=back

=head2 Instance Methods

=over

=item $object->create

Creates the object in FluidDB.

=item $object->id

Returns the UUID of the object, or C<undef> if it is new.

=item $object->has_id

Predicate to test whether the object has an ID.

=item $object->about

=item $object->about($about)

Gets/sets the about attribute. About can't be modified in existing
objects, the setter is only useful for new objects.

Note that you need to set the C<about> flag when you fetch an object
for this attribute to be initialized.

=item $object->has_about

Says whether the object has an about attribute.

Note that you need to set the C<about> flag when you fetch an object
for this attribute to be initialized.

=item $object->tag_paths

Returns the paths of the existing tags on the object as a (possibly
empty) arrayref of strings.

=item $object->tag($tag_or_tag_path, $value)

B<This interface is subject to revision>.

Tags an object. You can pass either a C<Tag> instance or a tag path in
the first argument.  By now C<$value> must be any of the primitive
FluidDB types integer, float, string, or set of strings (represented
as arrayref of strings). But this could change.

=item $object->value($tag_or_tag_path)

B<This interface is subject to revision>.

Gets the value of a tag on an object. You can refer to it either with a C<Tag> object
or a tag path. By now it returns a scalar of any of the primitive FluidDB types
integer, float, string, or set of strings (represented as arrayref of strings). But
this could change.

=back

=head1 FLUIDDB DOCUMENTATION

=over

=item FluidDB high-level description

L<http://doc.fluidinfo.com/fluidDB/objects.html>

=item FluidDB API documentation

L<http://doc.fluidinfo.com/fluidDB/api/objects.html>

=item FluidDB API specification

L<http://api.fluidinfo.com/fluidDB/api/*/objects/*>

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
