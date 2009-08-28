package Net::FluidDB::Value;
use Moose;

use JSON::XS;

has value          => (is => 'rw', isa => 'Any', required => 1);
has value_encoding => (is => 'rw', isa => 'Str', predicate => 'has_value_encoding');
has value_type     => (is => 'rw', isa => 'Str', predicate => 'has_value_type');

sub as_json {
    my $self = shift;
    my %h = ();
    $h{value}         = $self->value;
    $h{valueEncoding} = $self->value_encoding if $self->has_value_encoding;
    $h{valueType}     = $self->value_type     if $self->has_value_type;
    encode_json(\%h);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
