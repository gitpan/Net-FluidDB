package Net::FluidDB::Value::Native;
use Moose;
extends 'Net::FluidDB::Value';

use Carp;
use Net::FluidDB::JSON;
use MooseX::ClassAttribute;
class_has json => (is => 'ro', default => sub { Net::FluidDB::JSON->new });

# In the future more serialisation formats may be supported. When the time
# arrives we'll see how to add them to the design.
our $MIME_TYPE = 'application/vnd.fluiddb.value+json';

sub mime_type {
    $MIME_TYPE;
}

sub is_mime_type {
    my ($class, $mime_type) = @_;
    defined $mime_type && $mime_type eq $MIME_TYPE;
}

sub new_from_json {
    my ($class, $json) = @_;
    $class->type_from_json($json)->new(value => $class->json->decode($json));
}

# Give a JSON string like '5', or '7.32', or 'true', or '"foo"', this method
# returns the name of the class that represents the corresponding FluidDB
# native type. For example 'Net::FluidDB::Value::Boolean'.
sub type_from_json {
    my ($class, $json) = @_;

    my $type = do {
        if ($class->json->is_null($json)) {
            # instead of ordinary use(), to play nice with inheritance
            require Net::FluidDB::Value::Null;
            'Null';
        } elsif ($class->json->is_boolean($json)) {
            # instead of ordinary use(), to play nice with inheritance
            require Net::FluidDB::Value::Boolean;
            'Boolean';
        } elsif ($class->json->is_integer($json)) {
            # instead of ordinary use(), to play nice with inheritance
            require Net::FluidDB::Value::Integer;
            'Integer';
        } elsif ($class->json->is_float($json)) {
            # instead of ordinary use(), to play nice with inheritance
            require Net::FluidDB::Value::Float;
            'Float';
        } elsif ($class->json->is_string($json)) {
            # instead of ordinary use(), to play nice with inheritance
            require Net::FluidDB::Value::String;
            'String';
        } elsif ($class->json->is_array($json)) {
            # instead of ordinary use(), to play nice with inheritance
            require Net::FluidDB::Value::Set;
            'Set';
        } else {
            die "FluidDB has sent a native value of unknown type:\n$json\n";
        }
    };
    "Net::FluidDB::Value::$type";
}

our %VALID_ALIASES = map { $_ => 1 } qw(null boolean integer float string set);
sub type_from_alias {
    my ($class, $alias) = @_;
    
    if (exists $VALID_ALIASES{$alias}) {
        "Net::FluidDB::Value::\u$alias";
    } else {
        croak "unknown FluidDB type: $alias\n";
    }
}

sub to_json {
    # abstract
}

sub payload {
    shift->to_json;
}

sub is_native {
    1;
}

sub is_null {
    0;
}

sub is_boolean {
    0;
}

sub is_integer {
    0;
}

sub is_float {
    0;
}

sub is_string {
    0;
}

sub is_set {
    0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::FluidDB::Value::Native - FluidDB native values

=head1 SYNOPSIS

 $value = $object->value("fxn/rating");
 
=head1 DESCRIPTION

C<Net::FluidDB::Value::Native> models FluidDB native values.

FluidDB native types are null, boolean, integer, float, string, and set (of strings).

=head1 USAGE

=head2 Inheritance

C<Net::FluidDB::Value::Native> is a subclass of L<Net::FluidDB::Value>.

C<Net::FluidDB::Value::Native> is a parent class of L<Net::FluidDB::Value::Null>,
L<Net::FluidDB::Value::Boolean>, L<Net::FluidDB::Value::Integer>,
L<Net::FluidDB::Value::Float>, L<Net::FluidDB::Value::String>, and
L<Net::FluidDB::Value::Set>.

=head2 Instance Methods

Native values respond to the following predicates:

    $value->is_null;
    $value->is_boolean;
    $value->is_integer;
    $value->is_float;
    $value->is_string;
    $value->is_set;

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
