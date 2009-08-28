use strict;
use warnings;

use Test::More qw(no_plan);
use Time::HiRes 'time';
use Net::FluidDB;

sub random_about {
    "Net::FluidDB random about @{[time]} - @{[rand]}"
}

BEGIN {
    use_ok('Net::FluidDB::Object');
}

my $fdb = Net::FluidDB->new_for_testing;

my ($about, $object, $object2);

# creates an object with about
$about = random_about;
$object = Net::FluidDB::Object->new(fdb => $fdb, about => $about);
ok $object->create;
ok $object->has_id;
ok $object->object eq $object;
ok $object->about eq $about;

# fetches that very object
$object2 = Net::FluidDB::Object->get($fdb, $object->id, about => 1);
ok $object2->id eq $object->id;
ok $object2->about eq $object->about;

# creates an object without about
$object = Net::FluidDB::Object->new(fdb => $fdb);
ok $object->create;
ok $object->has_id;
ok !$object->has_about;

# fetches that very object
$object2 = Net::FluidDB::Object->get($fdb, $object->id);
ok $object2->id eq $object->id;
ok !$object2->has_about;
