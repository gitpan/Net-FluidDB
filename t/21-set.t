use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::Set';

my $v;

$v = Net::FluidDB::Value::Set->new;
ok $v->type_alias eq 'set';

ok '[]'             eq Net::FluidDB::Value::Set->new(value => [])->to_json;
ok '[""]'           eq Net::FluidDB::Value::Set->new(value => [''])->to_json;
ok '["true"]'       eq Net::FluidDB::Value::Set->new(value => ['true'])->to_json;
ok '["0","145.32"]' eq Net::FluidDB::Value::Set->new(value => [+0, 145.3200000])->to_json;

ok '[]'             eq Net::FluidDB::Value::Set->new(value => [])->payload;
ok '[""]'           eq Net::FluidDB::Value::Set->new(value => [''])->payload;
ok '["false"]'      eq Net::FluidDB::Value::Set->new(value => ['false'])->payload;
ok '["0","foo"]'    eq Net::FluidDB::Value::Set->new(value => [-0, 'foo'])->payload;

done_testing;
