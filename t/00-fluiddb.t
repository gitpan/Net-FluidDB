use strict;
use warnings;

use Test::More;

use_ok('Net::FluidDB');

my $fdb;

# -----------------------------------------------------------------------------

delete $ENV{FLUIDDB_USER};
delete $ENV{FLUIDDB_PASSWORD};

$fdb = Net::FluidDB->new;
ok !defined $fdb->user;
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(user => 'u');
ok $fdb->user eq 'u';
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(user => 'u', password => 'p');
ok $fdb->user eq 'u';
ok $fdb->password eq 'p';

# -----------------------------------------------------------------------------

$ENV{FLUIDDB_USER} = 'eu';

$fdb = Net::FluidDB->new;
ok $fdb->user eq 'eu';
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(user => 'u');
ok $fdb->user eq 'u';
ok !defined $fdb->password;

$fdb = Net::FluidDB->new(user => 'u', password => 'p');
ok $fdb->user eq 'u';
ok $fdb->password eq 'p';

# -----------------------------------------------------------------------------

$ENV{FLUIDDB_USER}     = 'eu';
$ENV{FLUIDDB_PASSWORD} = 'ep';

$fdb = Net::FluidDB->new;
ok $fdb->user eq 'eu';
ok $fdb->password eq 'ep';

$fdb = Net::FluidDB->new(user => 'u');
ok $fdb->user eq 'u';
ok $fdb->password eq 'ep';

$fdb = Net::FluidDB->new(user => 'u', password => 'p');
ok $fdb->user eq 'u';
ok $fdb->password eq 'p';

# -----------------------------------------------------------------------------

done_testing;

