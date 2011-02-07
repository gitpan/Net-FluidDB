use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::Float';

my $v;

$v = Net::FluidDB::Value::Float->new;
ok $v->type_alias eq 'float';

foreach $v (123, "+123", "123.0") {
    ok '123.0' eq Net::FluidDB::Value::Float->new(value => $v)->to_json;
    ok '123.0' eq Net::FluidDB::Value::Float->new(value => $v)->payload;
}

foreach $v (-123, "-123", "-123.0") {
    ok '-123.0' eq Net::FluidDB::Value::Float->new(value => $v)->to_json;
    ok '-123.0' eq Net::FluidDB::Value::Float->new(value => $v)->payload;
}

foreach $v (2.2e22, "2.2e22") {
    ok '2.2e+22' eq Net::FluidDB::Value::Float->new(value => $v)->to_json;
    ok '2.2e+22' eq Net::FluidDB::Value::Float->new(value => $v)->payload;
}

foreach $v (2.2e-22, "2.2e-22") {
    ok '2.2e-22' eq Net::FluidDB::Value::Float->new(value => $v)->to_json;
    ok '2.2e-22' eq Net::FluidDB::Value::Float->new(value => $v)->payload;
}

done_testing;
