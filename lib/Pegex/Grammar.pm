##
# name:      Pegex::Grammar
# abstract:  Pegex Grammar Base Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011, 2012

package Pegex::Grammar;
use Mouse;

# Grammar can be in text or tree form. Tree will be compiled from text.
# Grammar can also be stored in a file.
has file => (is => 'ro');
has text => (
    is => 'ro',
    lazy => 1,
    builder => 'make_text',
);
has tree => (
    is => 'ro',
    lazy => 1,
    builder => 'make_tree',
);

sub make_text {
    my ($self) = @_;
    my $filename = $self->file
        or return '';
    open TEXT, $filename
        or die "Can't open '$filename' for input\n:$!";
    return do {local $/; <TEXT>}
}

sub make_tree {
    my ($self) = @_;
    my $text = $self->text
        or die "Can't create a '" . ref($self) .
            "' grammar. No tree or text or file.";
    require Pegex::Compiler;
    return Pegex::Compiler->new->compile($text)->tree;
}

# This import is to support: perl -MPegex::Grammar::Module=compile
sub import {
    my ($package) = @_;
    if (((caller))[1] =~ /^-e?$/ and @_ == 2 and $_[1] eq 'compile') {
        $package->compile_into_module();
        exit;
    }
    if (my $env = $ENV{PERL_PEGEX_AUTO_COMPILE}) {
        my %modules = map {($_, 1)} split ',', $env;
        if ($modules{$package}) {
            if (my $grammar_file = $package->file) {
                if (-f $grammar_file) {
                    my $module = $package;
                    $module =~ s!::!/!g;
                    $module .= '.pm';
                    my $module_file = $INC{$module};
                    if (-M $grammar_file < -M $module_file) {
                        $package->compile_into_module();
                        local $SIG{__WARN__};
                        delete $INC{$module};
                        require $module;
                    }
                }
            }
        }
    }
}

sub compile_into_module {
    my ($package) = @_;
    my $grammar_file = $package->file;
    open GRAMMAR, $grammar_file
        or die "Can't open $grammar_file for input";
    my $grammar_text = do {local $/; <GRAMMAR>};
    close GRAMMAR;
    my $module = $package;
    $module =~ s!::!/!g;
    $module = "$module.pm";
    my $file = $INC{$module} or return;
    require Pegex::Compiler;
    my $perl = Pegex::Compiler->new->compile($grammar_text)->to_perl;
    open IN, $file or die $!;
    my $module_text = do {local $/; <IN>};
    close IN;
    $perl =~ s/^/  /gm;
    $module_text =~ s/^(sub\s+make_tree\s*\{).*?(^\})/$1\n$perl$2/ms;
    open OUT, '>', $file or die $!;
    print OUT $module_text;
    close OUT;
}

1;

=head1 SYNOPSIS

Define a Pegex grammar (for the Foo syntax):

    package Pegex::Grammar::Foo;
    use base 'Pegex::Grammar';

    use constant text => q{
    foo: <bar> <baz>
    ... rest of Foo grammar ...
    };
    use constant receiver => 'Pegex::Receiver';

then use it to parse some Foo:

    use Pegex::Grammar::Foo;
    my $ast = Pegex::Grammar::Foo->parse('my/file.foo');

=head1 DESCRIPTION

Pegex::Grammar is a base class for defining your own Pegex grammar classes. It
provides a single action method, `parse()`, that invokes a Pegex parser
(usually Pegex::Parser) for you, and then returns the kind of result that you
want it to. In other words, subclassing Pegex::Grammar is usually all you need
to do to create a parser/compiler for your language/syntax.

Pegex::Grammar classes are very simple. You just need to define a C<text>
property that returns your Pegex grammar string, or (if you don't want to
incur the compilation of the grammar each time) a C<tree> property which
returns a precompiled grammar.

You also need to define the receiver class or object that will produce a
result from your parse. 'Pegex::Receiver' is the easiest choice, as long as
you are satisfied which its results. Otherwise you can subclass it or define
something different.

=head1 PROPERTIES

There are 2 properties of a Pegex::Grammar: C<tree> and C<text>.

=over

=item tree

This is the data structure containing the compiled grammar for your syntax. It
is usually produced by C<Pegex::Compiler>. You can inline it in the C<tree>
method, or else the C<make_tree> method will be called to produce it.

The C<make_tree> method will call on Pegex::Compiler to compile the C<text>
property by default. You can define your own C<make_tree> method to do
override this behavior.

Often times you will want to generate your own Pegex::Grammar subclasses in an
automated fashion. The Pegex and TestML modules do this to be performant. This
also allows you to keep your grammar text in a separate file, and often in a
separate repository, so it can be shared by multiple programming language's
module implementations. See the src/ subdirectory in
L<http://github.com/ingydotnet/pegex-pm/>.

=item text

This is simply the text of your grammar, if you define this, you should
(probably) not define the C<tree> property. This grammar text will be
automatically compiled when the C<tree> is required.

=back
