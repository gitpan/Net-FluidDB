use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::TestUtils;

use_ok('Net::FluidDB::Object');

my $fdb = Net::FluidDB->new_for_testing;

my ($about, $object, $object2);

# creates an object with about
$about = random_about;
$object = Net::FluidDB::Object->new(fdb => $fdb, about => $about);
ok $object->create;
ok $object->has_id;
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

# tag paths
$object = Net::FluidDB::Object->new(fdb => $fdb);
ok @{$object->tag_paths} == 0;
ok $object->create;
ok @{$object->tag_paths} == 0;

$object = Net::FluidDB::Object->new(fdb => $fdb, about => random_about);
ok @{$object->tag_paths} == 0;
ok $object->create;
ok @{$object->tag_paths} == 1;
ok $object->tag_paths->[0] eq 'fluiddb/about';
$object2 = Net::FluidDB::Object->get($fdb, $object->id);
ok_sets_cmp $object->tag_paths, $object2->tag_paths;

# Now we are gonna do some variations just in case, but the proper place to
# test them is the suite of the Tag class.

# is_tag_path_present
$object = Net::FluidDB::Object->new(fdb => $fdb);
ok !$object->is_tag_path_present('fxn/rating');
ok !$object->is_tag_path_present('');

$object->_set_tag_paths(['fxn/rating']);
ok $object->is_tag_path_present('fxn/rating');
ok $object->is_tag_path_present('FxN/rating');

$object->_set_tag_paths(['fxn/rating', 'fxn/was-here']);
ok $object->is_tag_path_present('fxn/rating');
ok $object->is_tag_path_present('fxn/was-here');
ok $object->is_tag_path_present('FXN/rating');
ok $object->is_tag_path_present('FXN/was-here');
ok !$object->is_tag_path_present('fxn/RATING');
ok !$object->is_tag_path_present('fxn/WAS-HERE');

done_testing;