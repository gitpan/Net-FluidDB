use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::String';

my $v;

$v = Net::FluidDB::Value::String->new;
ok !$v->is_non_native;
ok  $v->is_native;
ok !$v->is_null;
ok !$v->is_boolean;
ok !$v->is_integer;
ok !$v->is_float;
ok  $v->is_string;
ok !$v->is_set;

foreach $v ('', 'true', 0, 100.2) {
    ok qq("$v") eq Net::FluidDB::Value::String->new(value => $v)->to_json;
    ok qq("$v") eq Net::FluidDB::Value::String->new(value => $v)->payload;
}

done_testing;
