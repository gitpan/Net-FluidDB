package Net::FluidDB::Object;
use Moose;
extends 'Net::FluidDB::Base';

use Carp;
use Scalar::Util qw(blessed);
use Net::FluidDB::Tag;
use Net::FluidDB::Value;
use Net::FluidDB::Value::Native;
use Net::FluidDB::Value::NonNative;
use Net::FluidDB::Value::Null;
use Net::FluidDB::Value::Boolean;
use Net::FluidDB::Value::Integer;
use Net::FluidDB::Value::Float;
use Net::FluidDB::Value::String;
use Net::FluidDB::Value::Set;

has id        => (is => 'ro', isa => 'Str', writer => '_set_id', predicate => 'has_id');
has about     => (is => 'rw', isa => 'Str', predicate => 'has_about');
has tag_paths => (is => 'ro', isa => 'ArrayRef[Str]', writer => '_set_tag_paths', default => sub { [] });

sub create {
    my $self = shift;

    my $payload = $self->has_about ? $self->json->encode({about => $self->about}) : undef;
    $self->fdb->post(
        path       => $self->abs_path('objects'),
        headers    => $self->fdb->headers_for_json,
        payload    => $payload,
        on_success => sub {
            my $response = shift;
            my $h = $self->json->decode($response->content);        
            $self->_set_id($h->{id});
            # Unset tag paths to force fetching the about tag.
            $self->_set_tag_paths(['fluiddb/about']) if $self->has_about;
            1;
        }
    );
}

sub get {
    my ($class, $fdb, $id, %opts) = @_;

    $opts{showAbout} = $class->true if delete $opts{about};
    $fdb->get(
        path       => $class->abs_path('objects', $id),
        query      => \%opts,
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
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
            @{$class->json->decode($response->content)->{ids}};
        }
    );
}

sub tag {
    my ($self, $tag_or_tag_path, @rest) = @_;

    my $tag_path = $self->get_tag_path_from_tag_or_tag_path($tag_or_tag_path);
    if (@rest < 2) {
        $self->tag_fdb_value_or_scalar($tag_path, @rest);
    } elsif (@rest == 2) {
        $self->tag_fdb_value_or_scalar_with_options($tag_path, @rest);
    } else {
        croak "invalid call to Object->tag()";
    }
}

sub tag_fdb_value_or_scalar {
    my ($self, $tag_path, $value) = @_;

    if (defined $value) {
        if (ref $value) {
            if (ref $value eq 'ARRAY') {
                $value = Net::FluidDB::Value::Set->new(value => $value);
            } elsif (blessed $value && $value->isa('Net::FluidDB::Value')) {
                # fine, do nothing
            } else {
                croak "$value is not undef nor a valid reference for tagging\n";
            }
        } else {
            croak "$value is not undef nor a valid reference for tagging\n";
        }
    } else {
        $value = Net::FluidDB::Value::Null->new;
    }
    $self->tag_fdb_value($tag_path, $value);
}

sub tag_fdb_value_or_scalar_with_options {
    my ($self, $tag_path, $type, $value) = @_;

    my $native_type = Net::FluidDB::Value::Native->type_from_alias($type);
    $value = $native_type ? 
             $native_type->new(value => $value) :
             Net::FluidDB::Value::NonNative->new(value => $value, mime_type => $type);
    $self->tag_fdb_value($tag_path, $value);
}

sub tag_fdb_value {
    my ($self, $tag_path, $value) = @_;
    
    my $status = $self->fdb->put(
        path    => $self->abs_path('objects', $self->id, $tag_path),
        headers => {'Content-Type' => $value->mime_type},
        payload => $value->payload
    );

    if ($status && !$self->is_tag_path_present($tag_path)) {
        push @{$self->tag_paths}, $tag_path;
    }

    $status;    
}

sub value {
    my ($self, $tag_or_tag_path, @rest) = @_;
    my $list_context = wantarray;
    
    my $tag_path = $self->get_tag_path_from_tag_or_tag_path($tag_or_tag_path);
    $self->fdb->get(
        path => $self->abs_path('objects', $self->id, $tag_path),
        on_success => sub {
            my $response = shift;
            my $value_object = Net::FluidDB::Value->new_from_mime_type_and_content(
                $response->headers->header('Content-Type'),
                $response->content
            );
            $list_context ? ($value_object->type, $value_object->value) : $value_object->value;
        }
    );
}

sub get_tag_path_from_tag_or_tag_path {
    my ($self, $tag_or_tag_path) = @_;
    ref($tag_or_tag_path) ? $tag_or_tag_path->path : $tag_or_tag_path;
}

sub is_tag_path_present {
    my ($self, $tag_path) = @_;

    foreach my $known_tag_path (@{$self->tag_paths}) {
        return 1 if Net::FluidDB::HasPath->equal_paths($tag_path, $known_tag_path);
    }
    return 0;
}

sub untag {
    my ($self, $tag_or_tag_path) = @_;

    my $tag_path = $self->get_tag_path_from_tag_or_tag_path($tag_or_tag_path);
    $self->fdb->delete(
        path       => $self->abs_path('objects', $self->id, $tag_path),
        on_success => sub {
            my @rest = grep { !Net::FluidDB::HasPath->equal_paths($tag_path, $_) } @{$self->tag_paths};
            $self->_set_tag_paths(\@rest);
            1;
        }
    );
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

 # tag
 $object->tag("fxn/likes");
 $object->tag("fxn/rating", integer => 10);
 $object->tag("fxn/avatar", 'image/png' => $image);

 # retrieve a tag value
 $value = $object->value("fxn/rating");
 
 # retrieve a tag value and its type
 ($type, $value) = $object->value("fxn/rating");
 
 # remove a tag
 $object->untag("fxn/rating");

 # search
 @ids = Net::FluidDB::Object->search($fdb, "has fxn/rating");
 
=head1 DESCRIPTION

C<Net::FluidDB::Object> models FluidDB objects.

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

C<Net::FluidDB> provides a convenience shortcut for this method.

=item Net::FluidDB::Object->search($fdb, $query)

Performs the query C<$query> and returns a (possibly empty) array of strings with
the IDs of the macthing objects.

C<Net::FluidDB> provides a convenience shortcut for this method.

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

=item $object->tag($tag_or_tag_path)

=item $object->tag($tag_or_tag_path, $value)

=item $object->tag($tag_or_tag_path, $type => $value)

Tags an object.

You can pass either a L<Net::FluidDB::Tag> instance or a tag path
in the first argument.

=over

=item Native values

You need to specify the FluidDB type of native values using one of
"null", "boolean", "integer", "float", "string", or "set":

    $object->tag("fxn/rating", integer => 7);

If C<$value> is C<undef> or an arrayref this is not required:

    $object->tag("fxn/tags");                    # type null
    $object->tag("fxn/tags", undef);             # type null
    $object->tag("fxn/tags", ["perl", "moose"]); # type set

The elements of arrayrefs are stringfied, since FluidDB sets are
sets of strings.

=item Non-native values

To tag with a non-native value use a suitable MIME type for it:

    $object->tag("fxn/foaf", "application/rdf+xml" => $foaf);

=back

=item $object->value($tag_or_tag_path)

Gets the value of a tag on an object.

You can refer to the tag either with a L<Net::FluidDB::Tag> instance or a tag path.

This method returns the very value in scalar context:

    $value = $object->value("fxn/rating");

and also the type in list context:

    ($type, $value) = $object->value("fxn/rating");

For native values the type is one of "null", "boolean", "integer", "float",
"string", or "set". For non-native values the type is their MIME type.

=back

=item $object->untag($tag_or_tag_path)

Untags an object.

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

Copyright (C) 2009-2010 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
