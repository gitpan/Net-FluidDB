package Net::FluidDB::User;
use Moose;
extends 'Net::FluidDB::Resource';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
