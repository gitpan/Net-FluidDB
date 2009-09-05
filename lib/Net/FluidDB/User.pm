package Net::FluidDB::User;
use Moose;
extends 'Net::FluidDB::Resource';

use JSON::XS;

has name => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fdb, $name) = @_;

    my $response = $fdb->get(
        path    => $class->abs_path('users', $name),
        headers => $fdb->accept_header_for_json
    );
    
    if ($response->is_success) {
        my $h = decode_json($response->content);
        $class->new(fdb => $fdb, %$h);
    } else {
        print STDERR $response->content, "\n";
        0;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
