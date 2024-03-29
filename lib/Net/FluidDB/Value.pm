# This is the root class of all FluidDB value types. The hierarchy splits
# into native types and non native types.
#
# These objects carry transport knowledge as of today. They know their MIME
# type, and they know how they should be travel as payload of HTTP requests.
# This could be internally redesigned in the future, but by now looks like
# a good compromise.
package Net::FluidDB::Value;
use Moose;

has mime_type => (is => 'ro', isa => 'Str');
has value     => (is => 'ro', isa => 'Any');

sub is_native {
    0;
}

sub is_non_native {
    0;
}

sub new_from_mime_type_and_content {
    my ($class, $mime_type, $content) = @_;
    
    # instead of ordinary use(), to play nice with inheritance
    require Net::FluidDB::Value::Native;
    if (Net::FluidDB::Value::Native->is_mime_type($mime_type)) {
        Net::FluidDB::Value::Native->new_from_json($content);
    } else {
        # instead of ordinary use(), to play nice with inheritance
        require Net::FluidDB::Value::NonNative;
        Net::FluidDB::Value::NonNative->new(mime_type => $mime_type, value => $content);
    }
}

sub payload {
    # abstract
}

sub type {
    my $self = shift;
    if ($self->is_native) {
        $self->type_alias;
    } else {
        $self->mime_type;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
