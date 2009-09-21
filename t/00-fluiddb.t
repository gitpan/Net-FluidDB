use strict;
use warnings;

use Test::More;

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

$fdb = Net::FluidDB->new_for_testing;
ok $fdb->username eq $fdb->user->username;

done_testing;

