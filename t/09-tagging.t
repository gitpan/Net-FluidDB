use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::Object;
use Net::FluidDB::Tag;
use Net::FluidDB::Value;
use Net::FluidDB::TestUtils;

my $fdb = Net::FluidDB->new_for_testing;

my ($object, $description, $name, $path, $tag, $value);

# creates an object with about
$object = Net::FluidDB::Object->new(fdb => $fdb, about => random_about);
ok $object->create;

$description = random_description;
$name = random_name;
$path = $fdb->username . "/$name";

# create a tag
$tag = Net::FluidDB::Tag->new(
    fdb         => $fdb,
    description => $description,
    indexed     => 1,
    path        => $path
);
ok $tag->create;

ok $object->tag($tag, 0);
ok $object->value($tag) == 0;

ok $object->tag($path, "foo bar baz");
ok $object->value($path) eq "foo bar baz";

ok $object->tag($path, [qw(foo bar baz)]);
is_deeply [sort @{$object->value($path)}], [sort qw(foo bar baz)];

ok $object->tag($path, Net::FluidDB::Value->new(value => 0));
ok $object->value($tag) == 0;

ok $object->tag($path, Net::FluidDB::Value->new(value => "foo bar baz"));
ok $object->value($tag) eq "foo bar baz";

ok $object->tag($path, Net::FluidDB::Value->new(value => [qw(foo bar baz)]));
is_deeply [sort @{$object->value($path)}], [sort qw(foo bar baz)];

ok $tag->delete;

done_testing;
