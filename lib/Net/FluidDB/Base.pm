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

=head1 NAME

Net::FluidDB::Base - The base class of all remote resources

=head1 SYNOPSIS

 my $fdb = $tag->fdb;

=head1 DESCRIPTION

Net::FluidDB::Base is the root class in the hierarchy of remote resources.
They need an instance of L<Net::FluidDB> to be able to communicate with
FluidDB.

You don't usually need this class, only the interface its children inherit.

=head1 USAGE

=head2 Class methods

All remote resources require a C<fdb> named argument in their constructors,
which comes from this class:

    my $tag = Net::FluidDB::Tag->new(fdb => $fdb, ...);

=head2 Instance Methods

=over 4

=item $base->fdb

Returns the L<Net::FluidDB> instance of used to communicate with FluidDB.

=back


=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut