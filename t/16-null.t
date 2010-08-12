use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::Null';

my $v;

$v = Net::FluidDB::Value::Null->new;
ok !$v->is_non_native;
ok  $v->is_native;
ok  $v->is_null;
ok !$v->is_boolean;
ok !$v->is_integer;
ok !$v->is_float;
ok !$v->is_string;
ok !$v->is_set;

ok 'null' eq Net::FluidDB::Value::Null->new->to_json;
ok 'null' eq Net::FluidDB::Value::Null->new->payload;

done_testing;
