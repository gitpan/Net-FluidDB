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

for (my $i = -3; $i <= 3; ++$i){
  my $object = Net::FluidDB::Object->new(fdb => $fdb);
  ok $object->create;
  ok $object->tag($tag, $i);
}

my @ids;

@ids = Net::FluidDB::Object->search($fdb, "has $path");
ok @ids == 7;
ok !ref for @ids;

@ids = Net::FluidDB::Object->search($fdb, "$path > -3 OR $path < 3");
ok @ids == 7;

@ids = Net::FluidDB::Object->search($fdb, "$path > 0");
ok @ids == 3;

@ids = Net::FluidDB::Object->search($fdb, "$path = 0");
ok @ids == 1;

@ids = Net::FluidDB::Object->search($fdb, "$path > 3");
ok @ids == 0;

@ids = Net::FluidDB::Object->search($fdb, "$path < -3");
ok @ids == 0;

done_testing;
