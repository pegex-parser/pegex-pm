# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }
use strict; use warnings;
package t::Bridge;
use base 'TestML::Bridge';
use TestML::Util;

use Pegex;
use Pegex::Compiler;
use Pegex::Bootstrap;
use Pegex::Tree;
use Pegex::Tree::Wrap;
use t::TestAST;
use YAML::XS;

sub parse_input {
    my ($self, $grammar, $input) = @_;
    pegex($grammar->value)->parse($input->value);
}

sub parse_to_tree {
    my ($self, $grammar, $input) = @_;
    pegex($grammar->value,
        receiver => 'Pegex::Tree',
    )->parse($input->value);
}

sub parse_to_tree_wrap {
    my ($self, $grammar, $input) = @_;
    pegex($grammar->value,
        receiver => 'Pegex::Tree::Wrap',
    )->parse($input->value);
}

sub parse_to_tree_test {
    my ($self, $grammar, $input) = @_;
    pegex($grammar->value,
        receiver => 't::TestAST',
    )->parse($input->value);
}

sub compile {
    my ($self, $grammar) = @_;
    my $compiler = Pegex::Compiler->new;
    my $tree = $compiler->parse($grammar->value)->combinate->tree;
    delete $tree->{'+toprule'};
    return $tree;
}

sub bootstrap_compile {
    my ($self, $grammar) = @_;
    my $compiler = Pegex::Bootstrap->new;
    my $tree = $compiler->parse($grammar->value)->combinate->tree;
    delete $tree->{'+toprule'};
    return $tree;
}
sub compress {
    my ($self, $grammar) = @_;
    my $grammar_text = $grammar->value;
    chomp($grammar_text);
    $grammar_text =~ s/(?<!;)\n(\w+\s*:)/;$1/g;
    $grammar_text =~ s/\s//g;

    # XXX mod/quant ERROR rules are too prtective here:
    $grammar_text =~ s/>%</> % </g;

    return "$grammar_text\n";
}

sub yaml {
    my ($self, $data) = @_;
    return YAML::XS::Dump($data->value);
}

sub clean {
    my ($self, $yaml) = @_;
    $yaml = $yaml->value;
    $yaml =~ s/^---\s//;
    $yaml =~ s/'(\d+)'/$1/g;
    $yaml =~ s/^- ~$/- /gm;
    return $yaml;
}

1;
