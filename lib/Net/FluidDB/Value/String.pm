package Net::FluidDB::Value::String;
use Moose;
extends 'Net::FluidDB::Value::Native';

sub to_json {
    my $self = shift;
    no warnings; # value may be undef
    $self->json->encode('' . $self->value);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
