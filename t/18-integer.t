use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::Integer';

my $v;

$v = Net::FluidDB::Value::Integer->new;
ok !$v->is_non_native;
ok  $v->is_native;
ok !$v->is_null;
ok !$v->is_boolean;
ok  $v->is_integer;
ok !$v->is_float;
ok !$v->is_string;
ok !$v->is_set;

foreach $v (123, "+123", "123.0", 123.45) {
    ok '123' eq Net::FluidDB::Value::Integer->new(value => $v)->to_json;
    ok '123' eq Net::FluidDB::Value::Integer->new(value => $v)->payload;
}

foreach $v (-123, "-123", "-123.0") {
    ok '-123' eq Net::FluidDB::Value::Integer->new(value => $v)->to_json;
    ok '-123' eq Net::FluidDB::Value::Integer->new(value => $v)->payload;
}

done_testing;
