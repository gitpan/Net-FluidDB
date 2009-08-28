use strict;
use warnings;

use Test::More qw(no_plan);
use Time::HiRes 'time';
use Net::FluidDB;

sub random_description {
    "Net::FluidDB tag description @{[time]} - @{[rand]}"
}

sub random_name {
    "net-fluiddb-tag-@{[time]}-@{[rand]}"
}

BEGIN {
    use_ok('Net::FluidDB::Tag');
}

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
ok $tag->has_id;
ok $tag->object->id eq $tag->id;
ok $tag->name eq $name;
ok $tag->path_of_namespace eq $fdb->user;
ok $tag->namespace->name eq $fdb->user;
ok $tag->path eq $path;

# fetch it
$tag2 = Net::FluidDB::Tag->get($fdb, $tag->path, description => 1);
ok $tag2->id eq $tag->id;
ok $tag2->name eq $tag->name;
ok $tag2->path_of_namespace eq $tag->path_of_namespace;
ok $tag2->namespace->name eq $tag->namespace->name;
ok $tag2->path eq $tag->path;

# delete it
ok $tag->delete;
