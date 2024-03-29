use Test::More;

use_ok('Net::FluidDB::HasPath');

# equal paths, corner cases
ok(Net::FluidDB::HasPath->equal_paths);
ok(!Net::FluidDB::HasPath->equal_paths(''));
ok(!Net::FluidDB::HasPath->equal_paths(undef, ''));

# equal paths, no slashes
ok(Net::FluidDB::HasPath->equal_paths('', ''));
ok(Net::FluidDB::HasPath->equal_paths('fxn', 'fxn'));
ok(!Net::FluidDB::HasPath->equal_paths('fxn', 'fxn/rating'));

# equal paths, usernames are case-insensitive, the rest is not
ok(Net::FluidDB::HasPath->equal_paths('fxn/rating', 'fxn/rating'));
ok(Net::FluidDB::HasPath->equal_paths('fxn/rating', 'FxN/rating'));
ok(!Net::FluidDB::HasPath->equal_paths('fxn/rating', 'fxn/RATING'));

# equal paths, namespaces
ok(Net::FluidDB::HasPath->equal_paths('fxn/books/rating', 'fxn/books/rating'));
ok(Net::FluidDB::HasPath->equal_paths('fxn/books/rating', 'FxN/books/rating'));
ok(!Net::FluidDB::HasPath->equal_paths('fxn/books/rating', 'fxn/BOOKS/rating'));
ok(!Net::FluidDB::HasPath->equal_paths('fxn/books/rating', 'fxn/books/RATING'));
ok(!Net::FluidDB::HasPath->equal_paths('fxn/books/rating', 'fxn/BOOKS/RATING'));

# equal paths, test metacharacters are escaped
ok(Net::FluidDB::HasPath->equal_paths('fxn/wtf?', 'fxn/wtf?'));
ok(!Net::FluidDB::HasPath->equal_paths('fxn/wtf?', 'fxn/wt'));
ok(Net::FluidDB::HasPath->equal_paths('fxn/...', 'fxn/...'));
ok(!Net::FluidDB::HasPath->equal_paths('fxn/...', 'fxn/foo'));

done_testing;