use strict;
use Test::More;
use Cwd 'cwd';
use Capture::Tiny 'capture_merged';
use Devel::Local '.';
# use XXX;

my $home = cwd;
my $repos = [
    # Perl Modules
    'pegex-json-pm',
    'testml-pm',
    'jsony-pm',
    'pegex-crontab-pm',
#     'cogdb-pm',
    'pegex-cmd-pm',
#     'pegex-yaml-pm',
#     'inline-pm',

    # Pegex Grammars
    'cdent-pgx',
    'crontab-pgx',
    'dtsl-pgx',
    'json-pgx',
    'kwim-pgx',
    'markup-socialtext-pgx',
    'pegex-pgx',
    'testml-pgx',
    'tt2-pgx',
    'yaml2-pgx',
    'yaml-pgx',
    'ypath-pgx',
];

for my $repo (@$repos) {
    chdir($home) or die;
    chdir("../$repo") or die "Can't find '$repo' repo";
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
    if (not -e '.git') {
        fail "$repo - is a git repo";
        return;
    }
    my ($branch_output) = run("git branch");
    $branch_output =~ /\*\s+(\w+)/ or die $branch_output;
    my $branch_name = $1;
    is $branch_name, 'master', "$repo - git branch is master";
    my ($status_output) = run("git status -s");
    if ($status_output) {
        fail "$repo - repo is clean";
        # diag $status_output;
    }
    else {
        pass "$repo - repo is clean";
    }
    return ($branch_name eq 'master' and not $status_output);
}

sub make_test {
    my ($repo) = @_;
    for my $dir (qw't xt') {
        next unless -d $dir;
        my $rc;
        my $cmd = "prove -lv $dir";
        my ($prove_output, $error) = run($cmd);
        if ($error) {
            # diag $prove_output;
            fail "$repo - $cmd";
        }
        else {
            pass "$repo - $cmd";
        }
    }
    return 1;
}

sub make_pegex {
    my ($repo) = @_;
    system("touch *.pgx") == 0 or die "touch failed in $repo";
    my $rc;
    my ($make_output, $error) = run("make");
    if ($error) {
        # diag $make_output;
        fail "$repo - make failed in $repo";
    }
    else {
        my ($diff_output) = run("git diff", 1);
        if ($diff_output) {
            # diag $diff_output;
            fail "$repo - unchanged after make";
            run("git reset --hard", 1);
        }
        else {
            pass "$repo - unchanged after make";
        }
    }
    return 1;
}

sub run {
    my ($cmd, $die) = (@_, 0);
    my $error;
    my $output = capture_merged {
        $error = system($cmd);
    };
    if ($die and $error) {
        die "Command '$cmd' failed:\n$output";
    }
    return ($output, $error);
}
