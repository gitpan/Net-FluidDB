package Net::FluidDB::Policy;
use Moose;
extends 'Net::FluidDB::ACL';

use JSON::XS;

has username => (is => 'ro', isa => 'Str');
has category => (is => 'ro', isa => 'Str');
has action   => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fdb, $user_or_username, $category, $action) = @_;
    
    my $username = $class->get_username_from_user_or_username($user_or_username);
    $fdb->get(
        path       => $class->abs_path('policies', $username, $category, $action),
        headers    => $fdb->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = decode_json($response->content);
            $class->new(
                fdb      => $fdb,
                username => $username,
                category => $category,
                action   => $action,
                %$h
            );
        }
    );
}

sub update {
    my $self = shift;

    my $payload = encode_json({policy => $self->policy, exceptions => $self->exceptions});
    $self->fdb->put(
        path    => $self->abs_path('policies', $self->username, $self->category, $self->action),
        headers => $self->fdb->headers_for_json,
        payload => $payload
    );
}

# Generates convenience methods to completely open or close resources.
#
#     open_namespaces
#     close_namespaces
#     open_tags
#     close_tags
#     open_tag_values
#     close_tag_values
#
while (my ($category, $actions) = each %{__PACKAGE__->Actions}) {
    no strict 'refs';
    foreach my $prefix ('open', 'close') {
        my $method_name = "${prefix}_${category}";
        $method_name =~ tr/-/_/; # tag-values -> tag_values
        *$method_name = sub {
            my ($class, $fdb, $user_or_username) = @_;

            my $username = $class->get_username_from_user_or_username($user_or_username);
            $username = $fdb->username if not defined $username;
            foreach my $action (@$actions) {
                my $policy = $class->get($fdb, $username, $category, $action);
                $policy->policy($prefix eq 'open' ? 'open' : 'closed');
                $policy->exceptions($prefix eq 'open' ? [] : [$username]);
                my $status = $policy->update;
                return $status unless $status;
            }
            1;            
        };
    }
}

# Generates getters for all pairs category/action:
#
#     get_create_policy_for_namespaces
#     ...
#     get_update_policy_for_tags
#     ...
#     get_read_policy_for_tag_values
#     ...
#
while (my ($category, $actions) = each %{__PACKAGE__->Actions}) {
    no strict 'refs';
    foreach my $action (@$actions) {
        my $method_name = "get_${action}_policy_for_${category}";
        $method_name =~ tr/-/_/; # tag-values -> tag_values
        *$method_name = sub {
            my ($class, $fdb, $user_or_username) = @_;
            my $username = $class->get_username_from_user_or_username($user_or_username);
            $class->get($fdb, $username, $category, $action);
        };
    }
}

sub get_username_from_user_or_username {
    my ($receiver, $user_or_username) = @_;
    ref $user_or_username ? $user_or_username->username : $user_or_username;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
