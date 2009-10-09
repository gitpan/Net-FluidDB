package Net::FluidDB::Value::Null;
use Moose;
extends 'Net::FluidDB::Value::Native';

sub value {
    undef;
}

sub to_json {
    'null';
}

sub is_null {
    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Value::Null - FluidDB null value

=head1 SYNOPSIS

 $value = $object->value("fxn/was-here");
 
=head1 DESCRIPTION

C<Net::FluidDB::Value::Null> models the FluidDB null value.

You will rarely need to construct one directly. Tagging objects
understands the alias 'null' to allow tagging with ordinary scalars.

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Value::Null> is a subclass of L<Net::FluidDB::Value::Native>.

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
