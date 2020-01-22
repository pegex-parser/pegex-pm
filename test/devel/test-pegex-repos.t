use strict;
use Test::More;
use Cwd 'cwd';
use Capture::Tiny 'capture_merged';

$ENV{PERL5LIB} = cwd . '/lib';
$ENV{TESTML_RUN} = 'perl5-tap';

my $home = cwd;
my $repos = [
    ### Perl Modules

    # 'inline-c-pm',        # Takes a long time
    'jsony-pm',
    'pegex-chess-pm',
    'pegex-cmd-pm',
    'pegex-cpan-packages-pm',
    'pegex-crontab-pm',
    'pegex-forth-pm',
    'pegex-json-pm',
    'pegex-vcard-pm',
    'testml1-pm',
    'vic',
    # 'yaml-pegex-pm',

    ### Pegex Grammars

    'chess-pgx',
    'crontab-pgx',
    'json-pgx',
    'jsony-pgx',
    # TODO: find out why this isn't working:
    # 'pegex-pgx',
    'swim-pgx',
    'testml-pgx',
    'vic-pgx',
    'yaml-pgx',
];

for my $repo (@$repos) {
    chdir($home) or die;
    my $repo_path = "../$repo";
    if (not -d "$repo_path") {
        diag "$repo does not exist";
        next;
    }
    chdir("$repo_path")
        or die "Can't chdir '$repo_path'";
    assert_git_ok($repo) or next;
    if ($repo =~ /-pm$/) {
        make_test($repo) or next;
    }
    elsif ($repo =~ /-pgx$/) {
        make_pegex($repo) or next;
    }
}

pass 'at least one pass else makes test fail spuriously';

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
    if ($branch_name eq 'master') {
        pass "$repo - git branch is master";
    }
    else {
        diag "$repo - not on branch master";
        return;
    }
    my ($status_output) = run("git status -s");
    if (not $status_output) {
        pass "$repo - repo is clean";
    }
    else {
        diag "$repo - is not git clean";
        # diag $status_output;
        return;
    }
    return 1;
}

sub make_test {
    my ($repo) = @_;
    for my $dir (qw'test test/devel') {
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
