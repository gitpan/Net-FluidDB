package Net::FluidDB::Value::Boolean;
use Moose;
extends 'Net::FluidDB::Value::Native';

sub to_json {
    my $self = shift;
    $self->value ? 'true' : 'false';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
