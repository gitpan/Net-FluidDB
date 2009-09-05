use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::TestUtils;

use_ok('Net::FluidDB::Tag');

my $fdb = Net::FluidDB->new_for_testing;

my ($tag, $tag2, $description, $name, $path);

$description = random_description;
$name = random_name;
$path = $fdb->user . "/$name";

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
ok $tag->path_of_namespace eq $fdb->user;
ok $tag->namespace->name eq $fdb->user;
ok $tag->path eq $path;

# fetch it
$tag2 = Net::FluidDB::Tag->get($fdb, $tag->path, description => 1);
ok $tag2->object_id eq $tag->object_id;
ok $tag2->name eq $tag->name;
ok $tag2->path_of_namespace eq $tag->path_of_namespace;
ok $tag2->namespace->name eq $tag->namespace->name;
ok $tag2->path eq $tag->path;

# delete it
ok $tag->delete;

done_testing;

