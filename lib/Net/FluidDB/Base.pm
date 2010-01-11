package Net::FluidDB::Base;
use Moose;

use JSON::XS;
use Carp;

use MooseX::ClassAttribute;
class_has json => (is => 'ro', default => sub { JSON::XS->new->utf8->allow_nonref });

has fdb  => (is => 'ro', isa => 'Net::FluidDB', required => 1);

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

# Utility method, could be extracted to a Utils module.
sub abs_path {
    my $receiver = shift;
    my $path = '/' . join('/', @_);
    $path =~ tr{/}{}s; # squash duplicated slashes
    $path =~ s{/$}{} unless $path eq '/';
    $path;
}

sub true {
    shift->as_json_boolean(1);
}

sub false {
    shift->as_json_boolean(0);
}

sub as_json_boolean {
    my ($receiver, $flag) = @_;
    $flag ? JSON::XS::true : JSON::XS::false;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Base - The base class of all remote resources

=head1 SYNOPSIS

 my $fdb = $tag->fdb;

=head1 DESCRIPTION

C<Net::FluidDB::Base> is the root class in the hierarchy of remote resources.
They need an instance of L<Net::FluidDB> to be able to communicate with
FluidDB.

You don't usually need this class, only the interface its children inherit.

=head1 USAGE

=head2 Class methods

All remote resources require a C<fdb> named argument in their constructors,
which comes from this class:

    my $tag = Net::FluidDB::Tag->new(fdb => $fdb, ...);

=head2 Instance Methods

=over

=item $base->fdb

Returns the L<Net::FluidDB> instance used to communicate with FluidDB.

=back


=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
