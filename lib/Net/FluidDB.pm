package Net::FluidDB;
use Moose;

use LWP::UserAgent;
use HTTP::Request;
use URI;
use JSON::XS;

use Net::FluidDB::Object;

our $VERSION           = '0.01';
our $USER_AGENT        = "Net::FluidDB/$VERSION ($^O)";
our $DEFAULT_PROTOCOL  = 'HTTP';
our $DEFAULT_HOST      = 'fluiddb.fluidinfo.com';
our $SANDBOX_HOST      = 'sandbox.fluidinfo.com';
our $JSON_CONTENT_TYPE = 'application/json';

has protocol => (is => 'rw', isa => 'Str', default => $DEFAULT_PROTOCOL);
has host     => (is => 'rw', isa => 'Str', default => $DEFAULT_HOST);
has user     => (is => 'rw', isa => 'Str');
has password => (is => 'rw', isa => 'Str');
has ua       => (is => 'ro', isa => 'LWP::UserAgent', writer => '_set_ua');

sub BUILD {
    my ($self, $attrs) = @_;

    my $ua = LWP::UserAgent->new(agent => $USER_AGENT);
    if ($attrs->{trace_http} || $attrs->{trace_http_requests}) {
        $ua->add_handler("request_send",  sub { shift->dump; return });
    }
    if ($attrs->{trace_http} || $attrs->{trace_http_responses}) {
        $ua->add_handler("response_done",  sub { shift->dump; return });
    }
    $self->_set_ua($ua);
}

sub new_for_testing {
    my ($class, %attrs) = @_;
    $class->new(user => 'test', password => 'test', host => $SANDBOX_HOST, %attrs);
}

sub get {
    shift->request("GET", @_);
}

sub post {
    shift->request("POST", @_);
}

sub head {
    shift->request("HEAD", @_);
}

sub put {
    shift->request("PUT", @_);
}

sub delete {
    shift->request("DELETE", @_);
}

sub request {
    my ($self, $method, %attrs) = @_;

    my $request = HTTP::Request->new;
    $request->authorization_basic($self->user, $self->password);
    $request->method($method);
    $request->uri($self->uri_for(%attrs));
    if (exists $attrs{headers}) {
        while (my ($header, $value) = each %{$attrs{headers}}) {
            $request->header($header => $value);
        }
    }
    $request->content($attrs{payload}) if exists $attrs{payload};

    $self->ua->request($request);
}

sub uri_for {
    my ($self, %attrs) = @_;

    my $uri = URI->new;
    $uri->scheme(lc $self->protocol);
    $uri->host($self->host);
    $uri->path($attrs{path});
    $uri->query_form($attrs{query}) if exists $attrs{query};
    $uri;
}

sub headers_for_json {
    return {
        'Accept'       => $JSON_CONTENT_TYPE,
        'Content-Type' => $JSON_CONTENT_TYPE
    };
}

sub accept_header_for_json {
    return {
        'Accept' => $JSON_CONTENT_TYPE
    }
}

sub content_type_header_for_json {
    return {
        'Content-Type' => $JSON_CONTENT_TYPE
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NAME

Net::FluidDB - A Perl interface to FluidDB

=head1 SYNOPSIS

 use Net::FluidDB;
 use Net::FluidDB::Object;
 use Net::FluidDB::Tag;
 use Net::FluidDB::Namespace;

 # predefined FluidDB client for playing around, points
 # to the sandbox with user test/test
 $fdb = Net::FluidDB->new_for_testing;
 $fdb = Net::FluidDB->new_for_testing(trace_http => 1);

 # FluidDB client pointing to production
 $fdb = Net::FluidDB->new(user => 'user', password => 'password');
 
 # create object, with optional about
 $object = Net::FluidDB::Object->new(
     fdb   => $fdb,
     about => $unique_about
 );
 $object->create;
 $object->id; # returns the object's ID in FluidDB 
 
 # get object by ID, optionally fetching about
 $object = Net::FluidDB::Object->get($fdb, $object_id, about => 1);

 # create tags
 $tag = Net::FluidDB::Tag->new(
    fdb         => $fdb,
    description => $description,
    indexed     => 1,
    path        => $path
 );
 $tag->create;
 $tag->namespace; # lazy loaded

 # get tag by path, optionally fetching descrition
 $tag = Net::FluidDB::Tag->get($fdb, $tag->path, description => 1);
 
 # tag objects using an existing tag path
 $object->tag("fxn/rating", 10);
 
 # tag objects using an existing tag object
 $object->tag($tag, "foo");
 
 # get a tag's value on an object by tag path
 $object->tag("fxn/rating"); # => 10

 # get a tag's value on an object by tag object
 $object->tag($tag); # => "foo"

 # delete a tag
 $tag->delete;
 
 # create a namespace by path
 $ns = Net::FluidDB::Namespace->new(
     fdb         => $fdb,
     path        => $path,
     description => $description
 );
 $ns->create;
 $ns->parent # lazy loaded

 # delete a namespace
 $ns->delete;


=head1 DESCRIPTION

Net::FluidDB provides an interface to the FluidDB API.

FluidDB's tagline is "a database with the heart of a wiki". It was launched
just a few days ago. Check these pages to know about FluidDB:

=over 4

=item * FluidDB Documentation: L<http://doc.fluidinfo.com/fluidDB/>

=item * FluidDB Essence blog entries: L<http://blogs.fluidinfo.com/fluidDB/category/essence/> 

=item * FluidDB API: L<L<http://api.fluidinfo.com/fluidDB/api/*/*/*>

=back

The design goal of Net::FluidDB is to offer a complete OO model for
FluidDB with a convenience layer on top of it. 


=head1 ALPHA VERSION & WORK IN PROGRESS

Net::FluidDB is in a very alpha stage:

=over 4

=item * The FluidDB API is partially implemented.

=item * The overall interface is taking shape. I consider the basis to be there,
but while in alpha the API may change.

=item * In particular, since FluidDB is new usage patterns have yet to arise.
They may influence the design of the interface.

=item * As of this version calls to FluidDB return a status flag. If there was
any failure the module only prints the response to STDERR and returns false.

=item * The module is underdocumented, to use a generous adjective :-).

=back


=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
