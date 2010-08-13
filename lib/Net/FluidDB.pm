package Net::FluidDB;
use Moose;

use LWP::UserAgent;
use HTTP::Request;
use URI;

use Net::FluidDB::Object;
use Net::FluidDB::Namespace;
use Net::FluidDB::Tag;
use Net::FluidDB::Policy;
use Net::FluidDB::Permission;
use Net::FluidDB::User;

our $VERSION           = '0.23';
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

sub _new_for_net_fluiddb_test_suite {
    my ($class, %attrs) = @_;
    $class->new(username => 'net-fluiddb', password => 'i98jijojijup92jo', %attrs);
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
    $request->content($opts{payload}) if defined $opts{payload};

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
            print STDERR $response->as_string;
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

#
# -- Convenience shortcuts ----------------------------------------------------
#

sub get_object {
    Net::FluidDB::Object->get(@_);
}

sub search {
    Net::FluidDB::Object->search(@_);
}

sub get_namespace {
    Net::FluidDB::Namespace->get(@_);
}

sub get_tag {
    Net::FluidDB::Tag->get(@_);
}

sub get_policy {
    Net::FluidDB::Policy->get(@_);
}

sub get_permission {
    Net::FluidDB::Permission->get(@_);
}

sub get_user {
    Net::FluidDB::User->get(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NAME

Net::FluidDB - A Perl interface to FluidDB

=head1 SYNOPSIS

 use Net::FluidDB;

 # predefined FluidDB client for playing around, points
 # to the sandbox with user test/test
 $fdb = Net::FluidDB->new_for_testing;
 $fdb = Net::FluidDB->new_for_testing(trace_http => 1);

 # FluidDB client pointing to production
 $fdb = Net::FluidDB->new(username => 'username', password => 'password');
 
 # FluidDB taking credentials from environment variables
 # FLUIDDB_USERNAME and FLUIDDB_PASSWORD
 $fdb = Net::FluidDB->new;

 # Resource getters
 my $object     = $fdb->get_object($object_id, about => 1);
 my $ns         = $fdb->get_namespace($path, description => 1);
 my $tag        = $fdb->get_tag($path, description => 1);
 my $policy     = $fdb->get_policy($user, $category, $action);
 my $permission = $fdb->get_permission($category, $path, $action);
 my $user       = $fdb->get_user($username);

 # Object search
 my @ids = $fdb->search("has fxn/rating");

=head1 DESCRIPTION

C<Net::FluidDB> provides an interface to the FluidDB API.

The documentation of Net::FluidDB does not explain FluidDB, though there are
links to relevant pages in the documentation of each class.

If you want to get familiar with FluidDB please check these pages:

=over

=item FluidDB high-level description

L<http://doc.fluidinfo.com/fluidDB/>

=item FluidDB API documentation

L<http://doc.fluidinfo.com/fluidDB/api/>

=item FluidDB API specification

L<http://api.fluidinfo.com/fluidDB/api/*/*/*>

=item FluidDB Essence blog posts

L<http://blogs.fluidinfo.com/fluidDB/category/essence/> 

=head1 USAGE

=head2 Class Methods

=over

=item Net::FluidDB->new(%attrs)

Returns an object for communicating with FluidDB.

This is a wrapper around L<LWP::UserAgent> and does not validate
credentials in the very constructor. If they are wrong requests
will fail when performed.

Attributes and options are:

=over

=item username

Your username in FluidDB. If not present uses the value of the
environment variable FLUIDDB_USERNAME.

=item password

Your password in FluidDB. If not present uses the value of the
environment variable FLUIDDB_PASSWORD.

=item protocol

Either 'HTTP' or 'HTTPS'. Defaults to 'HTTP'.

=item host

The FluidDB host. Defaults to I<fluiddb.fluidinfo.com>.

=item trace_http_requests

A flag, logs all HTTP requests if true.

=item trace_http_responses

A flag, logs all HTTP responses if true.

=item trace_http

A flag, logs all HTTP requests and responses if true. (Shorthand for
enabling the two above.)

=back 

=item Net::FluidDB->new_for_testing

Returns a C<Net::FluidDB> instance pointing to the sandbox with
"test"/"test". The host of the sandbox can be checked in the package
variable C<$Net::FluidDB::SANDBOX_HOST>.

=back

=head1 Instance Methods

=over

=item $fdb->username

=item $fdb->username($username)

Gets/sets the username.

=item $fdb->password

=item $fdb->password($password)

Gets/sets the password.

=item $fdb->protocol

=item $fdb->protocol($protocol)

Gets/sets the protocol, either 'HTTP' or 'HTTPS'.

=item $fdb->ua

Returns the instance of L<LWP::UserAgent> used to communicate with FluidDB.

=item $fdb->user

Returns the user on behalf of whom fdb is doing calls. This attribute
is lazy loaded. 

=item $fdb->get_object

Convenience shortcut for C<Net::FluidDB::Object::get>, see L<Net::FluidDB::Object>.

=item $fdb->search

Convenience shortcut for C<Net::FluidDB::Object::search>, see L<Net::FluidDB::Object>.

=item $fdb->get_namespace

Convenience shortcut for C<Net::FluidDB::Namespace::get>, see L<Net::FluidDB::Namespace>.

=item $fdb->get_tag

Convenience shortcut for C<Net::FluidDB::Tag::get>, see L<Net::FluidDB::Tag>.

=item $fdb->get_policy

Convenience shortcut for C<Net::FluidDB::Policy::get>, see L<Net::FluidDB::Policy>.

=item $fdb->get_permission

Convenience shortcut for C<Net::FluidDB::Permission::get>, see L<Net::FluidDB::Permission>.

=item $fdb->get_user

Convenience shortcut for C<Net::FluidDB::User::get>, see L<Net::FluidDB::User>.

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
