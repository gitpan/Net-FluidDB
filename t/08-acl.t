use strict;
use warnings;

use Test::More;
use Net::FluidDB;

use_ok('Net::FluidDB::ACL');

my $fdb = Net::FluidDB->_new_for_net_fluiddb_test_suite;
my $acl = Net::FluidDB::ACL->new(fdb => $fdb);

$acl->policy('open');
ok $acl->is_open;

$acl->policy('closed');
ok $acl->is_closed;

$acl->exceptions([]);
ok !$acl->has_exceptions;

$acl->exceptions(['test']);
ok $acl->has_exceptions;

done_testing;
