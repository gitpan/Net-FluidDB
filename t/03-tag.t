use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::TestUtils;

use_ok('Net::FluidDB::Tag');

my $fdb = Net::FluidDB->__new_for_net_fluiddb_testing;

my ($tag, $tag2, $description, $name, $path);

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
ok $tag->has_object_id;
ok $tag->object->id eq $tag->object_id;
ok $tag->name eq $name;
ok $tag->path_of_parent eq $fdb->username;
ok $tag->namespace->name eq $fdb->username;
ok $tag->path eq $path;

# fetch it
$tag2 = Net::FluidDB::Tag->get($fdb, $tag->path, description => 1);
ok $tag2->description eq $tag->description;
ok $tag2->indexed;
ok $tag2->object_id eq $tag->object_id;
ok $tag2->name eq $tag->name;
ok $tag2->path_of_parent eq $tag->path_of_parent;
ok $tag2->namespace->name eq $tag->namespace->name;
ok $tag2->path eq $tag->path;

# update description
$description = random_description;
$tag->description($description);
ok $tag->update;

$tag2 = Net::FluidDB::Tag->get($fdb, $tag->path, description => 1);
ok $tag2->description eq $tag->description;

# delete it
ok $tag->delete;

done_testing;
