use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::TestUtils;

use_ok('Net::FluidDB::Namespace');

my $fdb = Net::FluidDB->_new_for_net_fluiddb_test_suite;

my ($ns, $ns2, $name, $path, $description, $parent, $tag, @namespace_names, @tag_names, @tags);

# fetches the root namespace of the test user
$ns = Net::FluidDB::Namespace->get($fdb, $fdb->username); 
ok $ns;
ok $ns->has_object_id;
ok $ns->object->id eq $ns->object_id;
ok !$ns->parent;
ok $ns->name eq $fdb->username;
ok $ns->path eq $fdb->username;
ok $ns->path_of_parent eq "";

# creates a child namespace via path
$name = random_name;
$path = $fdb->username . "/$name";
$ns2 = Net::FluidDB::Namespace->new(fdb => $fdb, path => $path, description => random_description);
ok $ns2->create;
ok $ns2->has_object_id;
ok $ns2->name eq $name;
ok $ns2->parent;
ok $ns2->parent->name eq $fdb->username;
ok $ns2->path_of_parent eq $fdb->username;
ok $ns2->delete;

# creates a child namespace via parent namespace
$name = random_name;
$path = $fdb->username . "/$name";
$ns2 = Net::FluidDB::Namespace->new(fdb => $fdb, parent => $ns, name => $name, description => random_description);
ok $ns2->create;
ok $ns2->has_object_id;
ok $ns2->name eq $name;
ok $ns2->parent;
ok $ns2->parent->name eq $fdb->username;
ok $ns2->path_of_parent eq $fdb->username;
ok $ns2->delete;

# creates and updates a child namespace via path
$name = random_name;
$path = $fdb->username . "/$name";
$ns = Net::FluidDB::Namespace->new(fdb => $fdb, path => $path, description => random_description);
ok $ns->create;

$description = random_description;
$ns->description($description);
ok $ns->update;

$ns2 = Net::FluidDB::Namespace->get($fdb, $ns->path, description => 1);
ok $ns2->object_id eq $ns->object_id;
ok $ns2->description eq $ns->description;

ok $ns->delete;

# tests namespace_names
$name = random_name;
$path = $fdb->username . "/$name";
$parent = Net::FluidDB::Namespace->new(fdb => $fdb, path => $path, description => random_description);
ok $parent->create;

@namespace_names = (random_name, random_name, random_name);
foreach $name (@namespace_names) {
    $path = $fdb->username . "/$name";
    $ns2  = Net::FluidDB::Namespace->new(fdb => $fdb, parent => $parent, name => $name, description => random_description);
    ok $ns2->create;
}

$parent = Net::FluidDB::Namespace->get($fdb, $parent->path, description => 1, namespace_names => 1);
ok $parent;
ok_sets_cmp $parent->namespace_names, \@namespace_names;

# tests tag_names
@tags = ();
@tag_names = (random_name, random_name, random_name, random_name);
foreach $name (@tag_names) {
    $path = $fdb->username . "/$name";
    $tag  = Net::FluidDB::Tag->new(fdb => $fdb, namespace => $parent, name => $name, description => random_description, indexed => 0);
    ok $tag->create;
    push @tags, $tag;
}

$parent = Net::FluidDB::Namespace->get($fdb, $parent->path, description => 1, namespace_names => 1, tag_names => 1);
ok $parent;
ok_sets_cmp $parent->namespace_names, \@namespace_names;
ok_sets_cmp $parent->tag_names, \@tag_names;

ok $_->delete for @tags;

done_testing;

