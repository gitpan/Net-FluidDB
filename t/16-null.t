use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::Null';

my $v;

$v = Net::FluidDB::Value::Null->new;
ok $v->type_alias eq 'null';

ok 'null' eq Net::FluidDB::Value::Null->new->to_json;
ok 'null' eq Net::FluidDB::Value::Null->new->payload;

done_testing;
