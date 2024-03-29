use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;

use_ok 'Net::FluidDB::Value';

use Net::FluidDB::Value::Native;
use Net::FluidDB::TestUtils;

my $v;
my $nmt = Net::FluidDB::Value::Native->mime_type;

$v = Net::FluidDB::Value->new;
ok !$v->is_native;
ok !$v->is_non_native;
ok !$v->type;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, 'null');
ok $v->is_native;
ok $v->type eq 'null';
ok !defined $v->value;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, 'true');
ok $v->is_native;
ok $v->type eq 'boolean';
ok $v->value;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, 'false');
ok $v->is_native;
ok $v->type eq 'boolean';
ok !$v->value;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '0');
ok $v->is_native;
ok $v->type eq 'integer';
ok $v->value == 0;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '0.0');
ok $v->is_native;
ok $v->type eq 'float';
ok $v->value == 0;

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '"foo"');
ok $v->is_native;
ok $v->type eq 'string';
ok $v->value eq 'foo';

$v = Net::FluidDB::Value->new_from_mime_type_and_content($nmt, '["foo"]');
ok $v->is_native;
ok $v->type eq 'set';
ok_sets_cmp $v->value, ['foo'];

$v = Net::FluidDB::Value->new_from_mime_type_and_content('text/plain', '0');
ok $v->is_non_native;
ok $v->value eq '0';
ok $v->type eq 'text/plain';

done_testing;
