use strict;
use warnings;

use Test::More;

use_ok 'Net::FluidDB::Value';

use Net::FluidDB::Value::Native;

my $v;
my $nmt = Net::FluidDB::Value::Native->mime_type;

$v = Net::FluidDB::Value->new;
ok !$v->is_native;
ok !$v->is_non_native;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, 'null');
ok $v->is_native;
ok $v->is_null;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, 'true');
ok $v->is_native;
ok $v->is_boolean;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, 'false');
ok $v->is_native;
ok $v->is_boolean;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '0');
ok $v->is_native;
ok $v->is_integer;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '0.0');
ok $v->is_native;
ok $v->is_float;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '"foo"');
ok $v->is_native;
ok $v->is_string;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '["foo"]');
ok $v->is_native;
ok $v->is_set;

$v = Net::FluidDB::Value->new_from_mime_type_and_content('text/plain', '0');
ok $v->is_non_native;
ok $v->mime_type eq 'text/plain';
ok $v->value eq '0';

done_testing;
