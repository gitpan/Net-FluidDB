use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::Object;
use Net::FluidDB::Tag;
use Net::FluidDB::TestUtils;

my $fdb = Net::FluidDB->new_for_testing;

my $description = random_description;
my $name = random_name;
my $path = $fdb->username . "/$name";

my $tag = Net::FluidDB::Tag->new(
    fdb         => $fdb,
    description => $description,
    indexed     => 1,
    path        => $path
);
ok $tag->create;

my @object_ids = ();
for (my $i = -3; $i <= 3; ++$i){
  my $object = Net::FluidDB::Object->new(fdb => $fdb);
  ok $object->create;
  ok $object->tag($tag, integer => $i);
  push @object_ids, $object->id;
}

my @ids;

@ids = Net::FluidDB::Object->search($fdb, "has $path");
ok_sets_cmp \@ids, \@object_ids;

@ids = Net::FluidDB::Object->search($fdb, "$path > -3 OR $path < 3");
ok_sets_cmp \@ids, \@object_ids;

@ids = Net::FluidDB::Object->search($fdb, "$path > 0");
ok_sets_cmp \@ids, [ @object_ids[4 .. $#object_ids] ];

@ids = Net::FluidDB::Object->search($fdb, "$path = 0");
ok_sets_cmp \@ids, [ $object_ids[3] ];

@ids = Net::FluidDB::Object->search($fdb, "$path > 3");
ok_sets_cmp \@ids, [];

@ids = Net::FluidDB::Object->search($fdb, "$path < -3");
ok_sets_cmp \@ids, [];

done_testing;
