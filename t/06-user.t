use strict;
use warnings;

use Test::More;
use Net::FluidDB;

use_ok('Net::FluidDB::User');

my $fdb = Net::FluidDB->new_for_testing;
foreach my $name ('test', 'net-fluiddb', 'fxn') {
    my $user = Net::FluidDB::User->get($fdb, $name);
    ok $user->name eq $name;
}

done_testing;