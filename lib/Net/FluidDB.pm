package Net::FluidDB;
use Moose;

use LWP::UserAgent;
use HTTP::Request;
use URI;
use JSON::XS;

use Net::FluidDB::Object;
use Net::FluidDB::User;

our $VERSION           = '0.03';
our $USER_AGENT        = "Net::FluidDB/$VERSION ($^O)";
our $DEFAULT_PROTOCOL  = 'HTTP';
our $DEFAULT_HOST      = 'fluiddb.fluidinfo.com';
our $SANDBOX_HOST      = 'sandbox.fluidinfo.com';
our $JSON_CONTENT_TYPE = 'application/json';

has protocol => (is => 'rw', isa => 'Str', default => $DEFAULT_PROTOCOL);
has host     => (is => 'rw', isa => 'Str', default => $DEFAULT_HOST);
has username => (is => 'rw', isa => 'Maybe[Str]', default => sub { $ENV{FLUIDDB_USERNAME} });
has password => (is => 'rw', isa => 'Maybe[Str]', default => sub { $ENV{FLUIDDB_PASSWORD} });
has ua       => (is => 'ro', isa => 'LWP::UserAgent', writer => '_set_ua');
has user     => (is => 'ro', isa => 'Net::FluidDB::User', lazy_build => 1);

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

sub _build_user {
    my $self = shift;
    Net::FluidDB::User->get($self, $self->username);
}

sub new_for_testing {
    my ($class, %attrs) = @_;
    $class->new(username => 'test', password => 'test', host => $SANDBOX_HOST, %attrs);
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
    my ($self, $method, %opts) = @_;

    my $request = HTTP::Request->new;
    $request->authorization_basic($self->username, $self->password);
    $request->method($method);
    $request->uri($self->uri_for(%opts));
    if (exists $opts{headers}) {
        while (my ($header, $value) = each %{$opts{headers}}) {
            $request->header($header => $value);
        }
    }
    $request->content($opts{payload}) if exists $opts{payload};

    my $response = $self->ua->request($request);
    if ($response->is_success) {
        if (exists $opts{on_success}) {
            $opts{on_success}->($response);
        } else {
            1;
        }
    } else {
        if (exists $opts{on_failure}) {
            $opts{on_failure}->($response);
        } else {
            print STDERR $response->content, "\n";
            0;
        }        
    }
}

sub uri_for {
    my ($self, %opts) = @_;

    my $uri = URI->new;
    $uri->scheme(lc $self->protocol);
    $uri->host($self->host);
    $uri->path($opts{path});
    $uri->query_form($opts{query}) if exists $opts{query};
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
 use Net::FluidDB::Policy;
 use Net::FluidDB::Permission;
 use Net::FluidDB::User;

 # --- FluidDB ----------------------------------

 # predefined FluidDB client for playing around, points
 # to the sandbox with user test/test
 $fdb = Net::FluidDB->new_for_testing;
 $fdb = Net::FluidDB->new_for_testing(trace_http => 1);

 # FluidDB client pointing to production
 $fdb = Net::FluidDB->new(username => 'user', password => 'password');
 
 # FluidDB taking credentials from environment variables
 # FLUIDDB_USERNAME and FLUIDDB_PASSWORD
 $fdb = Net::FluidDB->new;
 
 # --- Objects ----------------------------------
 
 # create object, with optional about
 $object = Net::FluidDB::Object->new(
     fdb   => $fdb,
     about => $unique_about
 );
 $object->create;
 $object->id; # returns the object's ID in FluidDB 
 
 # get object by ID, optionally fetching about
 $object = Net::FluidDB::Object->get($fdb, $object_id, about => 1);

 # namespaces, tags, and users have objects
 $ns->object_id # a UUID
 $ns->object    # lazy loaded

 # --- Tags -------------------------------------

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
 $tag = Net::FluidDB::Tag->get($fdb, $tag_path, description => 1);
 
 # tag objects using an existing tag path
 $object->tag("fxn/rating", 10);
 
  # get a tag's value on an object by tag path
 $object->tag("fxn/rating"); # => 10
 
 # tag objects using an existing tag object
 $object->tag($tag, "foo");
 
 # get a tag's value on an object by tag object
 $object->tag($tag); # => "foo"
 
 # sets of strings are passed as arrayrefs of strings, note in the
 # example we may get the elements back in different order, that's
 # because we store and retrieve sets, not ordered collections
 $object->tag($tag, ["a", "b", "c"]);
 $object->value($tag); # => ["c", "a", "b"] 

 # delete a tag
 $tag->delete;

 # --- Namespaces -------------------------------

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

 # --- Policies ---------------------------------

 # raw getter
 $policy = Net::FluidDB::Policy->get($fdb, $username, 'namespaces', 'create');
 
 # convenience getter
 $policy = Net::FluidDB::Policy->get_create_policy_for_namespaces($fdb, $username);
 
 # checking a policy
 $policy->policy('open');
 $policy->exceptions(['test']);
 $policy->is_open;        # true
 $policy->is_closed;      # false
 $policy->has_exceptions; # true
 $policy->update;
 
 # bulk operations
 Net::FluidDB::Policy->open_namespaces;
 Net::FluidDB::Policy->close_tags; # sets the exception list to [$self]

 # --- Permissions ------------------------------

 $perm = Net::FluidDB::Permission->get($fdb, 'namespaces', 'test', 'create');
 $perm->policy('open');
 $perm->exceptions(['test']);
 $perm->is_open;        # true
 $perm->is_closed;      # false
 $perm->has_exceptions; # true
 $perm->update;

 # --- User -------------------------------------
 
 $user = Net::FluidDB::User->get($fdb, 'test');
 $user->username # => 'test'

=head1 DESCRIPTION

Net::FluidDB provides an interface to the FluidDB API.

FluidDB's tagline is "a database with the heart of a wiki". It was launched
just a few days ago. Check these pages to know about FluidDB:

=over 4

=item * FluidDB Documentation: L<http://doc.fluidinfo.com/fluidDB/>

=item * FluidDB Essence blog entries: L<http://blogs.fluidinfo.com/fluidDB/category/essence/> 

=item * FluidDB API: L<http://api.fluidinfo.com/fluidDB/api/*/*/*>

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

See L<http://dev.perl.org/licenses/> for more information.

=cut
