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

    if (@rest == 0) {
        $self->tag_fdb_value_or_scalar($tag_path);
    } elsif (@rest == 1) {
        $self->tag_fdb_value_or_scalar($tag_path, @rest);
    } elsif (@rest % 2 == 1) {
        $self->tag_fdb_value_or_scalar_with_options($tag_path, @rest);
    } else {
        croak "don't know"
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
    my ($self, $tag_path, $value, %opts) = @_;
    
    # It is OK to pass fdb_type AND mime_type as long as they match,
    # an undocumented feature guided by the "croak only if necessary"
    # principle.
    if (exists $opts{fdb_type} && exists $opts{mime_type}) {
        my $type = Net::FluidDB::Value::Native->type_from_alias($opts{fdb_type});
        if ($opts{mime_type} ne $type->mime_type) {
            croak <<MESSAGE;
FluidDB has a custom MIME type for native values which is not $opts{mime_type}.
You can leave that option out though, if fdb_type is present Net::FluidDB sets the
correct MIME type for you.
MESSAGE
        }
    }

    # At this point we have either one of them, or both but equivalent. This allows
    # us to branch in the following way.
    #
    # This chunk of code either leaves $value untouched, or reassigns to it according
    # to %opts. Goal is to tag the object with whatever $value we have after it.
    if ($opts{fdb_type}) {
        my $type = Net::FluidDB::Value::Native->type_from_alias($opts{fdb_type});
        if (blessed $value) {
            if ($value->isa('Net::FluidDB::Value::Native')) {
                # if fdb_type does not match perform a coercion, otherwise $value is fine as is
                $value = $type->new(value => $value->value) unless $value->isa($type);
            } else {
                # whatever, the value class will come up with something from it
                $value = $type->new(value => $value);
            }
        } else {
            $value = $type->new(value => $value);
        }
    } elsif ($opts{mime_type}) {
        $value = Net::FluidDB::Value::NonNative->new(value => $value, mime_type => $opts{mime_type});
    } else {
        croak "tagging with options requires either fdb_type (native values) or mime_type (non-native values)"
    }

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
    
    my $tag_path = $self->get_tag_path_from_tag_or_tag_path($tag_or_tag_path);
    $self->fdb->get(
        path => $self->abs_path('objects', $self->id, $tag_path),
        on_success => sub {
            my $response = shift;
            Net::FluidDB::Value->new_from_mime_type_and_content(
                $response->headers->header('Content-Type'),
                $response->content
            )
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
 $object->tag("fxn/rating", 10, fdb_type => 'integer');
 $object->tag("fxn/avatar", $image, mime_type => 'image/png');

 # retrieve a tag value
 $value = $object->("fxn/rating");

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

=item $object->tag($tag_or_tag_path, $value, %options)

Tags an object.

You can pass either a L<Net::FluidDB::Tag> instance instance or a tag path
in the first argument. Tag values may be native or non-native.

=over

=item Tagging with L<Net::FluidDB::Value>s

This method accepts L<Net::FluidDB::Value>s, in which case no options are
needed, but offers a convenience interface to be able to work with plain
scalars, see the next item.

=item Tagging with ordinary scalars

Tagging with ordinary scalars has two interfaces, one for native values,
and one for non-native values.

=over

=item Native values

For native value you need to pass a C<fdb_type> option to
indicate its FluidDB type. One of "null", "boolean", "integer", "float",
"string", or "set".

    $object->tag("fxn/rating", 10, fdb_type => 'integer');

If C<$value> is C<undef> or an arrayref this is not required:

    $object->tag("fxn/tags");                    # type null
    $object->tag("fxn/tags", undef);             # type null
    $object->tag("fxn/tags", ["perl", "moose"]); # type set

=item Non-native values

To tag with a non-native value you need to pass a C<mime_type> option with
a suitable MIME type for it:

    $object->tag("fxn/foaf", $foaf, mime_type => "application/rdf+xml");

=back

=back

=item $object->value($tag_or_tag_path)

Gets the value of a tag on an object.

You can refer to the tag either with a L<Net::FluidDB::Tag> instance or a tag path.

The returned value is an instance of some child of L<Net::FluidDB::Value>. The
C<value> method returns the actual scalar value:

    $value = $object->value("fxn/rating");
    print $value->value;

This object may be inspected: Any value responds to

    $value->is_native;
    $value->is_non_native;

Native values have predicates:

    $value->is_null;
    $value->is_boolean;
    $value->is_integer;
    $value->is_float;
    $value->is_string;
    $value->is_set;

The MIME type of a non-native value is also available:

    $value->mime_type;

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
