package Net::FluidDB::Tag;
use Moose;
extends 'Net::FluidDB::Base';

use Net::FluidDB::Namespace;

has description => (is => 'rw', isa => 'Str');
has indexed     => (is => 'ro', isa => 'Bool', required => 1);
has namespace   => (is => 'ro', isa => 'Net::FluidDB::Namespace', lazy_build => 1);

with 'Net::FluidDB::HasObject', 'Net::FluidDB::HasPath';

our %FULL_GET_FLAGS = (
    description => 1
);

sub _build_namespace {
    # TODO: add croaks for dependencies
    my $self = shift;
    Net::FluidDB::Namespace->get(
        $self->fdb,
        $self->path_of_parent,
        %Net::FluidDB::Namespace::FULL_GET_FLAGS
    );
}

sub parent {
    shift->namespace;
}

sub create {
    my $self = shift;
    
    my $payload = $self->json->encode({
        description => $self->description,
        indexed     => $self->as_json_boolean($self->indexed),
        name        => $self->name
    });
    
    $self->fdb->post(
        path       => $self->abs_path('tags', $self->path_of_parent),
        headers    => $self->fdb->headers_for_json,
        payload    => $payload,
        on_success => sub {
            my $response = shift;
            my $h = $self->json->decode($response->content);
            $self->_set_object_id($h->{id});            
        }
    );
}

sub get {
    my ($class, $fdb, $path, %opts) = @_;

    $opts{returnDescription} = $class->true if delete $opts{description};
    $fdb->get(
        path       => $class->abs_path('tags', $path),
        query      => \%opts,
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            my $t = $class->new(fdb => $fdb, path => $path, %$h);
            $t->_set_object_id($h->{id});
            $t;            
        }
    );
}

sub update {
    my $self = shift;

    my $payload = $self->json->encode({description => $self->description});
    $self->fdb->put(
        path    => $self->abs_path('tags', $self->path),
        headers => $self->fdb->headers_for_json,
        payload => $payload
    );
}

sub delete {
    my $self = shift;

    $self->fdb->delete(path => $self->abs_path('tags', $self->path));
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Tag - FluidDB tags

=head1 SYNOPSIS

 use Net::FluidDB::Tag;

 # create
 $tag = Net::FluidDB::Tag->new(
    fdb         => $fdb,
    description => $description,
    indexed     => 1,
    path        => $path
 );
 $tag->create;

 # get, optionally fetching descrition
 $tag = Net::FluidDB::Tag->get($fdb, $path, description => 1);
 $tag->namespace;

 # update
 $tag->description($new_description);
 $tag->update;

 # delete
 $tag->delete;
 
=head1 DESCRIPTION

C<Net::FluidDB::Tag> models FluidDB tags.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Tag> is a subclass of L<Net::FluidDB::Base>.

=head2 Roles

C<Net::FluidDB::Tag> consumes the roles L<Net::FluidDB::HasObject>, and L<Net::FluidDB::HasPath>.

=head2 Class methods

=over

=item Net::FluidDB::Tag->new(%attrs)

Constructs a new tag. The constructor accepts these parameters:

=over

=item fdb (required)

An instance of Net::FluidDB.

=item description (optional)

A description of this tag.

=item indexed (required)

A flag that tells FluidDB whether this tag should be indexed.

=item namespace (optional, but dependent)

The namespace you want to put this tag into. An instance of L<Net::FluidDB::Namespace>
representing an existing namespace in FluidDB.

=item name (optional, but dependent)

The name of the tag, which is the rightmost segment of its path.
The name of "fxn/rating" is "rating".

=item path (optional, but dependent)

The path of the tag, for example "fxn/rating".

=back

The C<description> attribute is not required because FluidDB allows fetching tags
without their description. It must be defined when creating or updating tags though.

The attributes C<namespace>, C<path>, and C<name> are mutually dependent. Ultimately
tag creation has to be able to send the path of the namespace and the name of the tag
to FluidDB. So you can set C<namespace> and C<name>, or just C<path>.

This constructor is only useful for creating new tags in FluidDB. Existing tags are
fetched with C<get>.

=item Net::FluidDB::Tag->get($fdb, $path, %opts)

Retrieves the tag with path C<$path> from FluidDB. Options are:

=over

=item description (optional, default false)

Tells C<get> whether you want to fetch the description.

=back

=item Net::FluidDB::Tag->equal_paths($path1, $path2)

Determines whether C<$path1> and C<$path2> are the same in FluidDB. The basic
rule is that the username fragment is case-insensitive, and the rest is not.

=back

=head2 Instance Methods

=over

=item $tag->create

Creates the tag in FluidDB.

=item $tag->update

Updates the tag in FluidDB. Only the description can be modified.

=item $tag->delete

Deletes the tag in FluidDB.

=item $tag->description

=item $tag->description($description)

Gets/sets the description of the tag.

Note that you need to set the C<description> flag when you fetch a
tag for this attribute to be initialized.

=item $tag->indexed

A flag, indicates whether this tag is indexed in FluidDB.

=item $tag->namespace

The namespace the tag belongs to, as an instance of L<Net::FluidDB::Namespace>.
This attribute is lazy loaded.

=item $tag->name

The name of the tag.

=item $tag->path

The path of the tag.

=back

=head1 FLUIDDB DOCUMENTATION

=over

=item FluidDB high-level description

L<http://doc.fluidinfo.com/fluidDB/tags.html>

=item FluidDB API documentation

L<http://doc.fluidinfo.com/fluidDB/api/namespaces-and-tags.html>

=item FluidDB API specification

L<http://api.fluidinfo.com/fluidDB/api/*/tags/*>

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
