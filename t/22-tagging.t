use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::Object;
use Net::FluidDB::Tag;
use Net::FluidDB::Value;
use Net::FluidDB::Value::Null;
use Net::FluidDB::Value::Boolean;
use Net::FluidDB::Value::Integer;
use Net::FluidDB::Value::Float;
use Net::FluidDB::Value::String;
use Net::FluidDB::Value::Set;
use Net::FluidDB::TestUtils;

my $fdb = Net::FluidDB->_new_for_net_fluiddb_test_suite;

my ($object, $description, $name, $path, $tag, $value);

## creates an object with about
$object = Net::FluidDB::Object->new(fdb => $fdb, about => random_about);
ok $object->create;

$description = random_description;
$name = random_name;
$path = $fdb->username . "/$name";

## create a tag
$tag = Net::FluidDB::Tag->new(
    fdb         => $fdb,
    description => $description,
    indexed     => 1,
    path        => $path
);
ok $tag->create;

ok $object->tag($tag);
$value = $object->value($tag);
ok $value->is_null;
ok !defined $value->value;
ok $object->is_tag_path_present($tag->path);

ok $object->tag($tag, undef);
$value = $object->value($tag);
ok $value->is_null;
ok !defined $value->value;
ok $object->is_tag_path_present($tag->path);

ok $object->tag($tag, 1, fdb_type => 'boolean');
$value = $object->value($tag);
ok $value->is_boolean;
ok $value->value;

ok $object->tag($tag, "this is true in boolean context", fdb_type => 'boolean');
$value = $object->value($tag);
ok $value->is_boolean;
ok $value->value;

ok $object->tag($tag, 0, fdb_type => 'boolean');
$value = $object->value($tag);
ok $value->is_boolean;
ok !$value->value;

ok $object->tag($tag, 0.0, fdb_type => 'boolean');
$value = $object->value($tag);
ok $value->is_boolean;
ok !$value->value;

ok $object->tag($tag, undef, fdb_type => 'boolean');
$value = $object->value($tag);
ok $value->is_boolean;
ok !$value->value;

ok $object->tag($tag, "", fdb_type => 'boolean');
$value = $object->value($tag);
ok $value->is_boolean;
ok !$value->value;

ok $object->tag($tag, "0", fdb_type => 'boolean');
$value = $object->value($tag);
ok $value->is_boolean;
ok !$value->value;

ok $object->tag($tag, 0, fdb_type => 'integer');
$value = $object->value($tag);
ok $value->is_integer;
ok $value->value == 0;

ok $object->tag($tag, 7, fdb_type => 'integer');
$value = $object->value($tag);
ok $value->is_integer;
ok $value->value == 7;

ok $object->tag($tag, -1, fdb_type => 'integer');
$value = $object->value($tag);
ok $value->is_integer;
ok $value->value == -1;

ok $object->tag($tag, "35foo", fdb_type => 'integer');
$value = $object->value($tag);
ok $value->is_integer;
ok $value->value == 35;

ok $object->tag($tag, "foo", fdb_type => 'integer');
$value = $object->value($tag);
ok $value->is_integer;
ok $value->value == 0;

ok $object->tag($tag, -3.14, fdb_type => 'integer');
$value = $object->value($tag);
ok $value->is_integer;
ok $value->value == -3;

ok $object->tag($tag, 0, fdb_type => 'float');
$value = $object->value($tag);
ok $value->is_float;
ok $value->value == 0;

ok $object->tag($tag, 0.5, fdb_type => 'float');
$value = $object->value($tag);
ok $value->is_float;
ok $value->value == 0.5;

ok $object->tag($tag, -0.5, fdb_type => 'float');
$value = $object->value($tag);
ok $value->is_float;
ok $value->value == -0.5;

ok $object->tag($tag, 1e9, fdb_type => 'float');
$value = $object->value($tag);
ok $value->is_float;
ok $value->value == 1e9;

ok $object->tag($tag, "", fdb_type => 'float');
$value = $object->value($tag);
ok $value->is_float;
ok $value->value == 0;

ok $object->tag($tag, '-2.5', fdb_type => 'float');
$value = $object->value($tag);
ok $value->is_float;
ok $value->value == -2.5;

ok $object->tag($tag, "this is a string", fdb_type => 'string');
$value = $object->value($tag);
ok $value->is_string;
ok $value->value eq "this is a string";

ok $object->tag($tag, "newlines \n\n\n newlines", fdb_type => 'string');
$value = $object->value($tag);
ok $value->is_string;
ok $value->value eq "newlines \n\n\n newlines";

ok $object->tag($tag, "", fdb_type => 'string');
$value = $object->value($tag);
ok $value->is_string;
ok $value->value eq "";

ok $object->tag($tag, undef, fdb_type => 'string');
$value = $object->value($tag);
ok $value->is_string;
ok $value->value eq "";

ok $object->tag($tag, 97, fdb_type => 'string');
$value = $object->value($tag);
ok $value->is_string;
ok $value->value eq "97";

ok $object->tag($tag, -2.7183, fdb_type => 'string');
$value = $object->value($tag);
ok $value->is_string;
ok $value->value eq "-2.7183";

ok $object->tag($tag, []);
$value = $object->value($tag);
ok $value->is_set;
ok_sets_cmp $value->value, [];

ok $object->tag($tag, ['foo', 'bar']);
$value = $object->value($tag);
ok $value->is_set;
ok_sets_cmp $value->value, ['foo', 'bar'];

ok $object->tag($tag, [0, 1], fdb_type => 'set');
$value = $object->value($tag);
ok $value->is_set;
ok_sets_cmp $value->value, ['0', '1'];

ok $object->tag($tag, 'this is plain text', mime_type => 'text/plain');
$value = $object->value($tag);
ok $value->is_non_native;
ok $value->mime_type eq 'text/plain';
ok $value->value eq 'this is plain text';

ok $object->tag($tag, '{}', mime_type => 'application/json');
$value = $object->value($tag);
ok $value->is_non_native;
ok $value->mime_type eq 'application/json';
ok $value->value eq '{}';

ok $object->tag($tag, Net::FluidDB::Value::Null->new);
$value = $object->value($tag);
ok $value->is_null;

ok $object->tag($tag, Net::FluidDB::Value::Boolean->new(value => 1));
$value = $object->value($tag);
ok $value->is_boolean;
ok $value->value;

ok $object->tag($tag, Net::FluidDB::Value::Integer->new(value => 7));
$value = $object->value($tag);
ok $value->is_integer;
ok $value->value == 7;

ok $object->tag($tag, Net::FluidDB::Value::Float->new(value => 0.01));
$value = $object->value($tag);
ok $value->is_float;
ok sprintf('%.2f', $value->value) eq '0.01';

ok $object->tag($tag, Net::FluidDB::Value::String->new(value => "foo bar baz"));
$value = $object->value($tag);
ok $value->is_string;
ok $value->value eq "foo bar baz";

ok $object->tag($tag, Net::FluidDB::Value::Set->new(value => [qw(foo bar baz)]));
$value = $object->value($tag);
ok $value->is_set;
ok_sets_cmp $value->value, [qw(foo bar baz)];

ok $object->tag($tag, Net::FluidDB::Value::NonNative->new(value => 'opaque', mime_type => 'text/plain'));
$value = $object->value($tag);
ok $value->is_non_native;
ok $value->value eq 'opaque';
ok $value->mime_type eq 'text/plain';

ok_dies { $object->tag($tag, 0) };
ok_dies { $object->tag($tag, 7) };
ok_dies { $object->tag($tag, 3.2) };
ok_dies { $object->tag($tag, "foo bar") };

ok_dies { $object->tag($tag, 0, fdb_type => 'unknown alias') };

ok_dies { $object->tag($tag, 0, fdb_type => 'integer', mime_type => 'text/plain') };
ok $object->tag($tag, 0, fdb_type => 'integer', mime_type => Net::FluidDB::Value::Native->mime_type);

# tests delegation in HasObject
foreach my $res ($fdb->user, $tag->namespace, $tag) {
    ok $res->tag($tag, 0, fdb_type => 'integer');
    ok $res->object->value($tag)->value == 0;
    ok $res->value($tag)->value == 0;
}

# untag
$path = $tag->path;
my $n = @{$object->tag_paths};
ok $object->untag($tag);
ok @{$object->tag_paths} == $n - 1;
ok !$object->is_tag_path_present($path);

$object = Net::FluidDB::Object->get($fdb, $object->id);
ok !$object->is_tag_path_present($path);

ok $tag->delete;

done_testing;
