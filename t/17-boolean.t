use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::Boolean';

my $v;

$v = Net::FluidDB::Value::Boolean->new;
ok !$v->is_non_native;
ok  $v->is_native;
ok !$v->is_null;
ok  $v->is_boolean;
ok !$v->is_integer;
ok !$v->is_float;
ok !$v->is_string;
ok !$v->is_set;

foreach $v (1, "00", 1.0, "false", []) {
    ok 'true' eq Net::FluidDB::Value::Boolean->new(value => $v)->to_json;
    ok 'true' eq Net::FluidDB::Value::Boolean->new(value => $v)->payload;
}

foreach $v (0, "0", undef, 0.0, "") {
    ok 'false' eq Net::FluidDB::Value::Boolean->new(value => $v)->to_json;
    ok 'false' eq Net::FluidDB::Value::Boolean->new(value => $v)->payload;
}

done_testing;
