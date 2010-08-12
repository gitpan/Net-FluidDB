use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::TestUtils;

my ($username, $password) = net_fluiddb_dev_credentials;

unless (defined $username && defined $password) {
    plan skip_all => skip_all_message;
    exit 0;
}

sub is_policy {
    ok shift->isa('Net::FluidDB::Policy');
}

skip_suite_unless_run_all;

use_ok('Net::FluidDB::Policy');

my $fdb = Net::FluidDB->_new_for_net_fluiddb_test_suite;
$fdb->username($username);
$fdb->password($password);

my ($policy, $policy2);
foreach my $u ($username, Net::FluidDB::User->get($fdb, $username), 'test', Net::FluidDB::User->get($fdb, 'test')) {
    $policy = Net::FluidDB::Policy->get($fdb, $u, 'namespaces', 'create');
    is_policy $policy;
    ok $policy->username eq Net::FluidDB::Policy->get_username_from_user_or_username($u);
    ok $policy->category eq 'namespaces';
    ok $policy->action   eq 'create';
    
    $policy = Net::FluidDB::Policy->get($fdb, $u, 'tags', 'update');
    is_policy $policy;
    ok $policy->username eq Net::FluidDB::Policy->get_username_from_user_or_username($u);
    ok $policy->category eq 'tags';
    ok $policy->action   eq 'update';

    $policy = Net::FluidDB::Policy->get($fdb, $u, 'tag-values', 'see');
    is_policy $policy;
    ok $policy->username eq Net::FluidDB::Policy->get_username_from_user_or_username($u);
    ok $policy->category eq 'tag-values';
    ok $policy->action   eq 'see';

    $policy = Net::FluidDB::Policy->get_create_policy_for_namespaces($fdb, $u);
    is_policy $policy;
    ok $policy->username eq Net::FluidDB::Policy->get_username_from_user_or_username($u);
    ok $policy->category eq 'namespaces';
    ok $policy->action   eq 'create';
    is_policy(Net::FluidDB::Policy->get_update_policy_for_namespaces($fdb, $u));
    is_policy(Net::FluidDB::Policy->get_delete_policy_for_namespaces($fdb, $u));
    is_policy(Net::FluidDB::Policy->get_list_policy_for_namespaces($fdb, $u));
    is_policy(Net::FluidDB::Policy->get_control_policy_for_namespaces($fdb, $u));
    
    $policy = Net::FluidDB::Policy->get_update_policy_for_tags($fdb, $u);
    is_policy $policy;
    ok $policy->username eq Net::FluidDB::Policy->get_username_from_user_or_username($u);
    ok $policy->category eq 'tags';
    ok $policy->action   eq 'update';
    is_policy(Net::FluidDB::Policy->get_delete_policy_for_tags($fdb, $u));
    is_policy(Net::FluidDB::Policy->get_control_policy_for_tags($fdb, $u));
    
    $policy = Net::FluidDB::Policy->get_see_policy_for_tag_values($fdb, $u);
    is_policy $policy;
    ok $policy->username eq Net::FluidDB::Policy->get_username_from_user_or_username($u);
    ok $policy->category eq 'tag-values';
    ok $policy->action   eq 'see';
    is_policy(Net::FluidDB::Policy->get_create_policy_for_tag_values($fdb, $u));
    is_policy(Net::FluidDB::Policy->get_read_policy_for_tag_values($fdb, $u));
    is_policy(Net::FluidDB::Policy->get_delete_policy_for_tag_values($fdb, $u));
    is_policy(Net::FluidDB::Policy->get_control_policy_for_tag_values($fdb, $u));
}

my $except_self = [$fdb->username];
while (my ($category, $actions) = each %{Net::FluidDB::Policy->Actions}) {
    foreach my $prefix ('open', 'close') {
        my $method_name = "${prefix}_${category}";
        $method_name =~ tr/-/_/;
        ok(Net::FluidDB::Policy->$method_name($fdb));
        foreach my $action (@$actions) {
            my $policy = Net::FluidDB::Policy->get($fdb, $fdb->username, $category, $action);
            is_policy $policy;
            if ($prefix eq 'open') {
                ok $policy->is_open;
                ok !$policy->has_exceptions;
            } else {
                ok $policy->is_closed;
                ok_sets_cmp $policy->exceptions, $except_self;
            }
        }
    }
}

while (my ($category, $actions) = each %{Net::FluidDB::Policy->Actions}) {
    foreach my $action (@$actions) {
        foreach my $pname ('open', 'closed') {
            foreach my $exceptions ([], ['foo'], ['foo', 'bar', 'baz', 'woo', 'zoo']) {
                $policy = Net::FluidDB::Policy->get($fdb, $fdb->username, $category, $action);
                is_policy($policy);
            
                $policy->policy($pname);
                $policy->exceptions($exceptions);
                ok $policy->update;

                $policy2 = Net::FluidDB::Policy->get($fdb, $fdb->username, $category, $action);
                is_policy($policy2);
                
                ok $policy->username eq $policy2->username;
                ok $policy->category eq $policy2->category;
                ok $policy->action  eq $policy2->action;
                ok $policy->policy eq $policy2->policy;
                ok_sets_cmp $policy->exceptions, $policy2->exceptions;
            }
        }
    }
}

done_testing;
