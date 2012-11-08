use strict;
use Test::More;
use Cwd 'cwd';
use Capture::Tiny 'capture_merged';
use Devel::Local '.', '../testml-pm';

my $home = cwd;
my $repos = [
    'pegex-json-pm',
    'testml-pm',
    'pegex-pgx',
    'testml-pgx',
];

for my $repo (@$repos) {
    chdir($home) or die;
    chdir("../$repo") or die "Can't find '$repo' repo";
    pass "Checking >>> $repo <<<";
    assert_git_ok($repo) or next;
    if ($repo =~ /-pm$/) {
        make_test($repo) or next;
    }
    elsif ($repo =~ /-pgx$/) {
        make_pegex($repo) or next;
    }
}

done_testing;

sub assert_git_ok {
    my ($repo) = @_;
    my $status_output = capture_merged {
        system("git status -s");
    };
    if ($status_output) {
        fail "repo is clean";
        diag $status_output;
    }
    else {
        pass "repo is clean";
    }
    my $branch_output = capture_merged {
        system("git branch");
    };
    $branch_output =~ /\*\s+(\w+)/ or die;
    my $branch_name = $1;
    is $branch_name, 'master', 'git branch is correct';

    return ($branch_name eq 'master' and not $status_output);
}

sub make_test {
    my ($repo) = @_;
    for my $dir (qw't xt') {
        next unless -d $dir;
        my $rc;
        my $cmd = "prove -lv $dir";
        my $prove_output = capture_merged {
            $rc = system($cmd);
        };
        if ($rc != 0) {
            diag $prove_output;
            fail $cmd;
        }
        else {
            pass $cmd;
        }
    }
    return 1;
}

sub make_pegex {
    my ($repo) = @_;
    system("touch *.pgx") == 0 or die "touch failed in $repo";
    my $rc;
    my $make_output = capture_merged {
        $rc = system("make");
    };
    if ($rc != 0) {
        diag $make_output;
        fail "make failed in $repo";
    }
    else {
        my $diff_output = system("git diff");
        if ($diff_output) {
            diag $diff_output;
            fail "$repo unchanged after make";
        }
        else {
            pass "$repo unchanged after make";
        }
    }
    return 1;
}
