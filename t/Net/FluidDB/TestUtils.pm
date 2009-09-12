package Net::FluidDB::TestUtils;
use base Exporter;
our @EXPORT = qw(
    random_about
    random_description
    random_name
    net_fluiddb_credentials
    skip_all_message
    skip_suite_unless_run_all
    ok_sets_cmp
);

use Time::HiRes 'time';
use Test::More;

sub random_about {
    random_token("about");
}

sub random_description {
    random_token("description");
}

sub random_name {
    random_token("name", '-');
}

sub random_token {
    my ($token, $separator) = @_;
    $separator ||= ' ';
    join $separator, "Net::FluidDB", $token, time, rand;
}

sub net_fluiddb_credentials {
    @ENV{'NET_FLUIDDB_USERNAME', 'NET_FLUIDDB_PASSWORD'};
}

sub skip_all_message {
    'this suite is brittle in a shared sandbox, only runs in the dev machine'
}

sub ok_sets_cmp {
    my ($a, $b) = @_;
    is_deeply [sort @$a], [sort @$b];
}

sub skip_suite_unless_run_all {
    unless ($ENV{NET_FLUIDDB_RUN_FULL_SUITE}) {
       plan skip_all => "set NET_FLUIDDB_RUN_FULL_SUITE to run these";
       exit 0;
    }
}

1;