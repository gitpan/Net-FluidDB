package Net::FluidDB::Base;
use Moose;

use Carp;

has fdb => (is => 'ro', isa => 'Net::FluidDB', required => 1);

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

# Utility method, could be extracted to a Utils module.
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
