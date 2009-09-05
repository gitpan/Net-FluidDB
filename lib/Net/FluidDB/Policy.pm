package Net::FluidDB::Policy;
use Moose;
extends 'Net::FluidDB::ACL';

use JSON::XS;

has user     => (is => 'ro', isa => 'Str');
has category => (is => 'ro', isa => 'Str');
has action   => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fdb, $user, $category, $action) = @_;
    
    my $response = $fdb->get(
        path    => $class->abs_path('policies', $user, $category, $action),
        headers => $fdb->accept_header_for_json
    );
    
    if ($response->is_success) {
        my $h = decode_json($response->content);
        $class->new(fdb => $fdb, user => $user, category => $category, action => $action, %$h);
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

sub update {
    my $self = shift;

    my $payload = encode_json({policy => $self->policy, exceptions => $self->exceptions});
    my $response = $self->fdb->put(
        path    => $self->abs_path('policies', $self->user, $self->category, $self->action),
        headers => $self->fdb->headers_for_json,
        payload => $payload
    );

    if ($response->is_success) {
        1;        
    } else {
        print STDERR $response->content, "\n";
        0;
    }
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
            my ($class, $fdb, $user) = @_;

            $user = $fdb->user if not defined $user;
            foreach my $action (@$actions) {
                my $policy = $class->get($fdb, $user, $category, $action);
                $policy->policy($prefix eq 'open' ? 'open' : 'closed');
                $policy->exceptions($prefix eq 'open' ? [] : [$user]);
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
            my ($class, $fdb, $user) = @_;
            $class->get($fdb, $user, $category, $action);
        };
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
