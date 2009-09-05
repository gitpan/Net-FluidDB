use strict;
use warnings;

use Test::More;
use Net::FluidDB::Value;
use JSON::XS;

sub ok_json {
    my ($json1, $json2) = @_;
    is_deeply decode_json($json1), decode_json($json2);
}

sub new_json {
   my %h = @_;
   encode_json(\%h);
}

sub new_value {
    Net::FluidDB::Value->new(@_)->as_json;
}

BEGIN {
    use_ok('Net::FluidDB::Value');
}

ok_json new_json(value => 0), new_value(value => 0);
ok_json new_json(value => "0"), new_value(value => "0");
ok_json new_json(value => [qw(foo bar baz)]), new_value(value => [qw(foo bar baz)]);

ok_json new_json(value => 0, valueType => '1'), new_value(value => 0, value_type => '1');
ok_json new_json(value => 0, valueEncoding => '2'), new_value(value => 0, value_encoding => '2');

ok_json new_json(value => 0, valueType => '1', valueEncoding => '2'), new_value(value => 0, value_type => '1', value_encoding => '2');

done_testing;
