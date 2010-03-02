use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB::Object;
use Net::FluidDB::Namespace;
use Net::FluidDB::Tag;
use Net::FluidDB::Policy;
use Net::FluidDB::Permission;
use Net::FluidDB::User;
use Net::FluidDB::TestUtils;

use_ok('Net::FluidDB');

my $fdb;

# -----------------------------------------------------------------------------

delete $ENV{FLUIDDB_USERNAME};
delete $ENV{FLUIDDB_PASSWORD};

$fdb = Net::FluidDB->new;
ok !defined $fdb->username;
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(username => 'u');
ok $fdb->username eq 'u';
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(username => 'u', password => 'p');
ok $fdb->username eq 'u';
ok $fdb->password eq 'p';

# -----------------------------------------------------------------------------

$ENV{FLUIDDB_USERNAME} = 'eu';

$fdb = Net::FluidDB->new;
ok $fdb->username eq 'eu';
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(username => 'u');
ok $fdb->username eq 'u';
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(username => 'u', password => 'p');
ok $fdb->username eq 'u';
ok $fdb->password eq 'p';

# -----------------------------------------------------------------------------

$ENV{FLUIDDB_USERNAME} = 'eu';
$ENV{FLUIDDB_PASSWORD} = 'ep';

$fdb = Net::FluidDB->new;
ok $fdb->username eq 'eu';
ok $fdb->password eq 'ep';

$fdb = Net::FluidDB->new(username => 'u');
ok $fdb->username eq 'u';
ok $fdb->password eq 'ep';

$fdb = Net::FluidDB->new(username => 'u', password => 'p');
ok $fdb->username eq 'u';
ok $fdb->password eq 'p';

# -----------------------------------------------------------------------------

$fdb = Net::FluidDB->__new_for_net_fluiddb_testing;
ok $fdb->username eq $fdb->user->username;

# -----------------------------------------------------------------------------

$fdb = Net::FluidDB->__new_for_net_fluiddb_testing;

my $user = $fdb->user;
my $object = $user->object;

my $object2 = $fdb->get_object($object->id, about => 1);
ok $object2->isa('Net::FluidDB::Object');
ok $object2->id eq $object->id;
ok $object2->about eq $object->about;

my $ns = $fdb->get_namespace($fdb->username);
ok $ns->isa('Net::FluidDB::Namespace');
ok $ns->path eq $fdb->username;

my $description = random_description;
my $name        = random_name;
my $path        = $fdb->username . "/$name";

my $tag = Net::FluidDB::Tag->new(
    fdb         => $fdb,
    description => $description,
    indexed     => 1,
    path        => $path
);
ok $tag->create;
ok $object->tag($tag, integer => 0);

my @ids = $fdb->search("$path = 0");
ok @ids == 1;
ok $ids[0] eq $object->id;

my $tag2 = $fdb->get_tag($tag->path);
ok $tag2->isa('Net::FluidDB::Tag');
ok $tag2->path eq $tag->path;
ok $tag->delete;

my $policy = $fdb->get_policy($user, 'namespaces', 'create');
ok $policy->isa('Net::FluidDB::Policy');
ok $policy->username eq $user->username;
ok $policy->category eq 'namespaces';
ok $policy->action eq 'create';

my $permission = $fdb->get_permission('namespaces', $user->username, 'create');
ok $policy->isa('Net::FluidDB::Policy');
ok $permission->category eq 'namespaces';
ok $permission->action eq 'create';

my $user2 = $fdb->get_user($user->username);
ok $user2->isa('Net::FluidDB::User');
ok $user2->username eq $user->username;

done_testing;
