package Net::FluidDB::ACL;
use Moose;
use MooseX::ClassAttribute;
extends 'Net::FluidDB::Base';

class_has Actions => (
    is => 'ro',
    isa => 'HashRef[ArrayRef[Str]]',
    default => sub {{
        'namespaces' => [qw(create update delete list control)],
        'tags'       => [qw(update delete control)],
        'tag-values' => [qw(see create read update delete control)]
    }}
);

has policy     => (is => 'rw', isa => 'Str');
has exceptions => (is => 'rw', isa => 'ArrayRef[Str]');

sub is_open {
    my $self = shift;
    $self->policy eq 'open' 
}

sub is_closed {
    my $self = shift;
    $self->policy eq 'closed' 
}

sub has_exceptions {
    my $self = shift;
    @{$self->exceptions} != 0;
}

no Moose;
no MooseX::ClassAttribute;
__PACKAGE__->meta->make_immutable;

1;
