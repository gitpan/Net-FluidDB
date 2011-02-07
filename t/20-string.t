use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::String';

my $v;

$v = Net::FluidDB::Value::String->new;
ok $v->type_alias eq 'string';

foreach $v ('', 'true', 0, 100.2) {
    ok qq("$v") eq Net::FluidDB::Value::String->new(value => $v)->to_json;
    ok qq("$v") eq Net::FluidDB::Value::String->new(value => $v)->payload;
}

done_testing;
