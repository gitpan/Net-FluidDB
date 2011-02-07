package Net::FluidDB::Value::Null;
use Moose;
extends 'Net::FluidDB::Value::Native';

sub value {
    undef;
}

sub to_json {
    'null';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
