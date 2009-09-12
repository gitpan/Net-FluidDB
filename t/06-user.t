use strict;
use warnings;

use Test::More;
use Net::FluidDB;

use_ok('Net::FluidDB::User');

my $fdb = Net::FluidDB->new_for_testing;
foreach my $username ('test', 'net-fluiddb', 'fxn') {
    my $user = Net::FluidDB::User->get($fdb, $username);
    ok $user->username eq $username;
    ok $user->name eq $username;
}

done_testing;