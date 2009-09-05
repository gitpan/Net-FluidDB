use strict;
use warnings;

use Test::More;

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

done_testing;