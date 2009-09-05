use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::TestUtils;

use_ok('Net::FluidDB::Namespace');

my $fdb = Net::FluidDB->new_for_testing;

my ($ns, $ns2, $name, $path, $description);

# fetches the root namespace of the test user
$ns = Net::FluidDB::Namespace->get($fdb, $fdb->user); 
ok $ns;
ok $ns->has_object_id;
ok $ns->object->id eq $ns->object_id;
ok !$ns->parent;
ok $ns->name eq $fdb->user;
ok $ns->path eq $fdb->user;
ok $ns->path_of_parent eq "";

# creates a child namespace via path
$name = random_name;
$path = $fdb->user . "/$name";
$ns2 = Net::FluidDB::Namespace->new(fdb => $fdb, path => $path, description => random_description);
ok $ns2->create;
ok $ns2->has_object_id;
ok $ns2->name eq $name;
ok $ns2->parent;
ok $ns2->parent->name eq $fdb->user;
ok $ns2->path_of_parent eq $fdb->user;
ok $ns2->delete;

# creates and updates a child namespace via path
$name = random_name;
$path = $fdb->user . "/$name";
$ns = Net::FluidDB::Namespace->new(fdb => $fdb, path => $path, description => random_description);
ok $ns->create;

$description = random_description;
$ns->description($description);
ok $ns->update;

$ns2 = Net::FluidDB::Namespace->get($fdb, $ns->path, description => 1);
ok $ns2->object_id eq $ns->object_id;
ok $ns2->description eq $ns->description;

ok $ns->delete;

done_testing;

