use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB::TestUtils;

use_ok 'Net::FluidDB::Value::Native';

my $v;

ok(Net::FluidDB::Value::Native->new->is_native);
ok(!Net::FluidDB::Value::Native->new->is_non_native);

ok(Net::FluidDB::Value::Native->mime_type eq $Net::FluidDB::Value::Native::MIME_TYPE);

ok(Net::FluidDB::Value::Native->is_mime_type($Net::FluidDB::Value::Native::MIME_TYPE));
ok(!Net::FluidDB::Value::Native->is_mime_type('text/html'));
ok(!Net::FluidDB::Value::Native->is_mime_type(undef));

ok 'Net::FluidDB::Value::Null'         eq Net::FluidDB::Value::Native->type_from_json('null');
ok 'Net::FluidDB::Value::Boolean'      eq Net::FluidDB::Value::Native->type_from_json('true');
ok 'Net::FluidDB::Value::Boolean'      eq Net::FluidDB::Value::Native->type_from_json('false');
ok 'Net::FluidDB::Value::Integer'      eq Net::FluidDB::Value::Native->type_from_json('500');
ok 'Net::FluidDB::Value::Integer'      eq Net::FluidDB::Value::Native->type_from_json('-500');
ok 'Net::FluidDB::Value::Float'        eq Net::FluidDB::Value::Native->type_from_json('500.0');
ok 'Net::FluidDB::Value::Float'        eq Net::FluidDB::Value::Native->type_from_json('-500.0');
ok 'Net::FluidDB::Value::Float'        eq Net::FluidDB::Value::Native->type_from_json('1e2');
ok 'Net::FluidDB::Value::Float'        eq Net::FluidDB::Value::Native->type_from_json('-1e2');
ok 'Net::FluidDB::Value::String'       eq Net::FluidDB::Value::Native->type_from_json('""');
ok 'Net::FluidDB::Value::String'       eq Net::FluidDB::Value::Native->type_from_json('"500"');
ok 'Net::FluidDB::Value::Set' eq Net::FluidDB::Value::Native->type_from_json('[]');
ok 'Net::FluidDB::Value::Set' eq Net::FluidDB::Value::Native->type_from_json('[""]');
ok 'Net::FluidDB::Value::Set' eq Net::FluidDB::Value::Native->type_from_json('["500","foo"]');

ok(Net::FluidDB::Value::Native->new_from_json('null')->is_null);
ok(Net::FluidDB::Value::Native->new_from_json('true')->is_boolean);
ok(Net::FluidDB::Value::Native->new_from_json('false')->is_boolean);
ok(Net::FluidDB::Value::Native->new_from_json('500')->is_integer);
ok(Net::FluidDB::Value::Native->new_from_json('-500')->is_integer);
ok(Net::FluidDB::Value::Native->new_from_json('0.0')->is_float);
ok(Net::FluidDB::Value::Native->new_from_json('-0.0')->is_float);
ok(Net::FluidDB::Value::Native->new_from_json('1e2')->is_float);
ok(Net::FluidDB::Value::Native->new_from_json('-1e2')->is_float);
ok(Net::FluidDB::Value::Native->new_from_json('""')->is_string);
ok(Net::FluidDB::Value::Native->new_from_json('"foo"')->is_string);
ok(Net::FluidDB::Value::Native->new_from_json('"foo bar baz"')->is_string);
ok(Net::FluidDB::Value::Native->new_from_json('[]')->is_set);
ok(Net::FluidDB::Value::Native->new_from_json('[""]')->is_set);
ok(Net::FluidDB::Value::Native->new_from_json('["foo","bar"]')->is_set);

ok "Net::FluidDB::Value::Null"    eq Net::FluidDB::Value::Native->type_from_alias('null');
ok "Net::FluidDB::Value::Boolean" eq Net::FluidDB::Value::Native->type_from_alias('boolean');
ok "Net::FluidDB::Value::Integer" eq Net::FluidDB::Value::Native->type_from_alias('integer');
ok "Net::FluidDB::Value::Float"   eq Net::FluidDB::Value::Native->type_from_alias('float');
ok "Net::FluidDB::Value::String"  eq Net::FluidDB::Value::Native->type_from_alias('string');
ok "Net::FluidDB::Value::Set"     eq Net::FluidDB::Value::Native->type_from_alias('set');
ok_dies { Net::FluidDB::Value::Native->type_from_alias('unknown alias') };

done_testing;
