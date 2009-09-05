use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::FluidDB;
use Net::FluidDB::Namespace;
use Net::FluidDB::Tag;
use Net::FluidDB::Policy;
use Net::FluidDB::TestUtils;

sub is_permission {
    ok shift->isa('Net::FluidDB::Permission');
}

sub reset_policies {
    my $fdb = shift;
    ok(Net::FluidDB::Policy->close_namespaces($fdb));
    ok(Net::FluidDB::Policy->close_tags($fdb));
    ok(Net::FluidDB::Policy->close_tag_values($fdb));
}

sub check_perm {
    my $perm = shift;
    my $perm2 = Net::FluidDB::Permission->get($perm->fdb, $perm->category, $perm->path, $perm->action);
    is_permission $perm2;
                
    ok $perm2->category eq $perm->category;
    ok $perm2->action  eq $perm->action;
    ok $perm2->policy eq $perm->policy;
    ok_sets_cmp $perm2->exceptions, $perm->exceptions;
}

my ($user, $password) = net_fluiddb_credentials;

unless (defined $user && defined $password) {
    plan skip_all => skip_all_message;
    exit 0;
}

use_ok('Net::FluidDB::Permission');

my ($perm, $path, $ns, $tag);

my $fdb = Net::FluidDB->new(user => $user, password => $password);


# --- Seed data ---------------------------------------------------------------

reset_policies($fdb);

$path = "$user/" . random_name;
$ns = Net::FluidDB::Namespace->new(
    fdb         => $fdb,
    description => random_description,
    path        => $path
);
ok $ns->create;

$path = "$user/" . random_name;
$tag = Net::FluidDB::Tag->new(
    fdb         => $fdb,
    description => random_description,
    path        => $path
);
ok $tag->create;

my %paths = (
    'namespaces' => $ns->path,
    'tags'       => $tag->path,
    'tag-values' => $tag->path
);


# --- GET ---------------------------------------------------------------------

reset_policies($fdb);

while (my ($category, $actions) = each %{Net::FluidDB::Permission->Actions}) {
    foreach my $action (@$actions) {
        my $perm = Net::FluidDB::Permission->get($fdb, $category, $paths{$category}, $action);
        is_permission $perm;

        ok $perm->is_closed;
        ok_sets_cmp $perm->exceptions, [$user];
    }
}


# --- PUT except for control --------------------------------------------------

while (my ($category, $actions) = each %{Net::FluidDB::Permission->Actions}) {
    foreach my $action (@$actions) {
        next if $action eq 'control';
        foreach my $pname ('open', 'closed') {
            foreach my $exceptions ([], ['foo'], ['foo', 'bar', 'baz', 'woo', 'zoo']) {
                my $perm = Net::FluidDB::Permission->get($fdb, $category, $paths{$category}, $action);
                is_permission $perm;

                $perm->policy($pname);
                $perm->exceptions($exceptions);
                ok $perm->update;
                check_perm $perm;
            }
        }
    }
}


# --- PUT with control --------------------------------------------------------

reset_policies($fdb);

foreach my $category (keys %{Net::FluidDB::Permission->Actions}) {
    foreach my $pname ('open', 'closed') {
        foreach my $exceptions ([], ['foo'], ['foo', 'bar', 'baz', 'woo', 'zoo']) {
            my @e = @$exceptions;
            push @e, $user if $pname eq 'closed';
            my $perm = Net::FluidDB::Permission->get($fdb, $category, $paths{$category}, 'control');
            is_permission $perm;

            $perm->policy($pname);
            $perm->exceptions(\@e);
            ok $perm->update;
            check_perm $perm;
        }
    }

    # Commit suicide, we have to test closing with an empty exception list somehow
    # and we won't be able to delete these $ns or $tag.
    my $perm = Net::FluidDB::Permission->get($fdb, $category, $paths{$category}, 'control');
    is_permission($perm);
    
    $perm->policy('closed');
    $perm->exceptions([]);
    ok $perm->update;
    # can't read this back, when we implement exceptions we could try and catch here (TODO) 
}

done_testing;
