use strict; use warnings;

package TestMLBridge;
use base 'TestML::Bridge';

use lib 'lib';  # Avoid using testml/ext/perl5/Pegex*
use Pegex;
use Pegex::Compiler;
use Pegex::Bootstrap;
use Pegex::Tree;
use Pegex::Tree::Wrap;
use TestAST;
use YAML::PP;

sub compile {
    my ($self, $grammar) = @_;
    my $tree = Pegex::Compiler->new->parse($grammar)->tree;
    delete $tree->{'+toprule'};
    delete $tree->{'_'};
    delete $tree->{'__'};
    return $tree;
}

sub bootstrap_compile {
    my ($self, $grammar) = @_;
    my $tree = Pegex::Bootstrap->new->parse($grammar)->tree;
    delete $tree->{'+toprule'};
    delete $tree->{'_'};
    delete $tree->{'__'};
    return $tree;
}

sub compress {
    my ($self, $grammar) = @_;
    $grammar = $grammar;
    $grammar =~ s/(?<!;)\n(\w+\s*:)/;$1/g;
    $grammar =~ s/\s//g;

    # XXX mod/quant ERROR rules are too protective here:
    $grammar =~ s/>%</> % </g;

    return "$grammar\n";
}

sub yaml {
    my ($self, $data) = @_;
    my $tree = $data;
    YAML::PP
        ->new(schema => ['Core', 'Perl'])
        ->dump_string($tree);
}

sub clean {
    my ($self, $yaml) = @_;
    $yaml = $yaml;
    $yaml =~ s/^---\s//;
    $yaml =~ s/'(\d+)'/$1/g;
    $yaml =~ s/^- ~$/- /gm;
    return $yaml;
}

sub parse_input {
    my ($self, $grammar, $input) = @_;
    my $parser = pegex($grammar);
    return $parser->parse($input);
}

sub parse_to_tree {
    my ($self, $grammar, $input) = @_;
    require Pegex::Tree;
$::testing = 0; # XXX
    my $parser = pegex($grammar, 'Pegex::Tree');
$parser->grammar->tree;
    # use XXX; XXX $parser->grammar->tree;
$::testing = 1; # XXX
    return $parser->parse($input);
}

sub parse_to_tree_wrap {
    my ($self, $grammar, $input) = @_;
$::testing = 0; # XXX
    my $parser = pegex($grammar, 'Pegex::Tree::Wrap');
$parser->grammar->tree;
$::testing = 1; # XXX
    return $parser->parse($input);
}

sub parse_to_tree_test {
    my ($self, $grammar, $input) = @_;
    my $parser = pegex($grammar, 'TestAST');
    return $parser->parse($input);
}

1;
