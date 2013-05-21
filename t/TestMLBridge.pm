# BEGIN { $Pegex::Parser::Debug = 1 }
use strict; use warnings;

package TestMLBridge;
use base 'TestML::Bridge';
use TestML::Util;
use Pegex;
use Pegex::Compiler;
use Pegex::Bootstrap;
use Pegex::Tree;
use Pegex::Tree::Wrap;
use TestAST;
use YAML::XS;

# use XXX;
sub compile {
    my ($self, $grammar) = @_;
    my $tree = Pegex::Compiler->new->parse($grammar->value)->combinate->tree;
    delete $tree->{'+toprule'};
    return native $tree;
}

sub bootstrap_compile {
    my ($self, $grammar) = @_;
    my $tree = Pegex::Bootstrap->new->parse($grammar->value)->combinate->tree;
    delete $tree->{'+toprule'};
    return native $tree;
}

sub compress {
    my ($self, $grammar) = @_;
    $grammar = $grammar->value;
    $grammar =~ s/(?<!;)\n(\w+\s*:)/;$1/g;
    $grammar =~ s/\s//g;

    # XXX mod/quant ERROR rules are too protective here:
    $grammar =~ s/>%</> % </g;

    return str "$grammar\n";
}

sub yaml {
    my ($self, $data) = @_;
    return str YAML::XS::Dump($data->value);
}

sub clean {
    my ($self, $yaml) = @_;
    $yaml = $yaml->value;
    $yaml =~ s/^---\s//;
    $yaml =~ s/'(\d+)'/$1/g;
    $yaml =~ s/^- ~$/- /gm;
    return str $yaml;
}

sub parse_input {
    my ($self, $grammar, $input) = @_;
    my $parser = pegex($grammar->value);
    return native $parser->parse($input->value);
}

sub parse_to_tree {
    my ($self, $grammar, $input) = @_;
    require Pegex::Tree;
    my $parser = pegex($grammar->value, 'Pegex::Tree');
    return native $parser->parse($input->value);
}

sub parse_to_tree_wrap {
    my ($self, $grammar, $input) = @_;
    my $parser = pegex($grammar->value, 'Pegex::Tree::Wrap');
    return native $parser->parse($input->value);
}

sub parse_to_tree_test {
    my ($self, $grammar, $input) = @_;
    my $parser = pegex($grammar->value, 'TestAST');
    return native $parser->parse($input->value);
}

1;
