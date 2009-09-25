use strict;
use warnings;

use JSON::XS;
use Test::More;

sub is_json_true {
    my $value = shift;
    JSON::XS::is_bool($value) && $value
}

sub is_json_false {
    my $value = shift;
    JSON::XS::is_bool($value) && !$value
}

use_ok('Net::FluidDB::Base');

ok(Net::FluidDB::Base->abs_path() eq '/');
ok(Net::FluidDB::Base->abs_path('') eq '/');
ok(Net::FluidDB::Base->abs_path('/foo') eq '/foo');
ok(Net::FluidDB::Base->abs_path('/foo/') eq '/foo');
ok(Net::FluidDB::Base->abs_path('foo') eq '/foo');
ok(Net::FluidDB::Base->abs_path('foo', 'bar') eq '/foo/bar');
ok(Net::FluidDB::Base->abs_path('/foo', '/bar') eq '/foo/bar');
ok(Net::FluidDB::Base->abs_path('/foo', '/bar/') eq '/foo/bar');
ok(Net::FluidDB::Base->abs_path('foo', '//bar', 'baz//') eq '/foo/bar/baz');

ok is_json_true Net::FluidDB::Base->true;
ok is_json_false Net::FluidDB::Base->false;

ok is_json_true Net::FluidDB::Base->as_json_boolean("foo");
ok is_json_true Net::FluidDB::Base->as_json_boolean(7);
ok is_json_true Net::FluidDB::Base->as_json_boolean([]);

ok is_json_false Net::FluidDB::Base->as_json_boolean("");
ok is_json_false Net::FluidDB::Base->as_json_boolean("0");
ok is_json_false Net::FluidDB::Base->as_json_boolean(undef);

done_testing;