use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value::NonNative';

my $v;

$v = Net::FluidDB::Value::NonNative->new(value => 'foo');

ok !$v->is_native;
ok $v->is_non_native;
ok $v->payload eq 'foo';

done_testing;

