package Net::FluidDB::Tag;
use Moose;
extends 'Net::FluidDB::Base';

use Net::FluidDB::Namespace;
use JSON::XS;

with 'Net::FluidDB::HasObject';

has description => (is => 'rw', isa => 'Str');
has indexed     => (is => 'ro', isa => 'Bool', required => 1);
has namespace   => (is => 'ro', isa => 'Net::FluidDB::Namespace', lazy_build => 1);
has name        => (is => 'ro', isa => 'Str', lazy_build => 1);
has path        => (is => 'ro', isa => 'Str', lazy_build => 1);

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

sub update {
    my $self = shift;

    my $payload = encode_json({description => $self->description});
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

Net::FluidDB::Tag models FluidDB tags.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Tag> is a subclass of L<Net::FluidDB::Base>.

=head2 Roles

C<Net::FluidDB::Tag> consumes the role L<Net::FluidDB::HasObject>.

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
