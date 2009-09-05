package Net::FluidDB::Resource;
use Moose;
extends 'Net::FluidDB::Base';
use Net::FluidDB::Object;

use Carp;

has fdb       => (is => 'ro', isa => 'Net::FluidDB', required => 1);
has object    => (is => 'ro', isa => 'Net::FluidDB::Object', lazy_build => 1);
has object_id => (is => 'ro', isa => 'Str', writer => '_set_object_id', predicate => 'has_object_id');

sub _build_object {
    # TODO: croak if no ID.
    my $self = shift;
    Net::FluidDB::Object->get($self->fdb, $self->object_id, about => 1);
}

sub create {
    shift->croak_about("create"); 
}

sub get {
    shift->croak_about("get"); 
}

sub update {
    shift->croak_about("update"); 
}

sub delete {
    shift->croak_about("delete"); 
}

sub croak_about {
    my ($receiver, $method) = @_;
    my $name = ref $receiver;
    $name ||= $receiver;
    croak "$method is not supported (or yet implemented) for $name";
}

sub abs_path {
    my $receiver = shift;
    my $path = '/' . join('/', @_);
    $path =~ tr{/}{}s; # squash duplicated slashes
    $path =~ s{/$}{} unless $path eq '/';
    $path;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
