package Net::FluidDB::Value::NonNative;
use Moose;
extends 'Net::FluidDB::Value';

sub is_non_native {
    1;
}

sub payload {
    shift->value;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
