##
# name:      Pegex::Grammar
# abstract:  Pegex Grammar Base Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Grammar;
use Pegex::Mo;

# Grammar can be in text or tree form. Tree will be compiled from text.
has 'text' => default => sub {
    my $self = shift;
    die "Can't create a '" . ref($self) . "' grammar. No 'text' or 'tree'.";
};
has 'tree' => builder => 'tree_';
sub tree_ {
    require Pegex::Compiler;
    Pegex::Compiler->compile($_[0]->text)->tree;
}

# Parser and receiver classes to use.
has 'parser' => default => sub {'Pegex::Parser'};
has 'receiver' => default => sub {
    require Pegex::Receiver;
    Pegex::Receiver->new(wrap => 1);
};

sub parse {
    my $self = shift;
    $self = $self->new unless ref $self;

    die "Usage: " . ref($self) . '->parse($input [, $start_rule]'
        unless 1 <= @_ and @_ <= 2;

    my $parser = $self->parser;
    if (not ref $parser) {
        eval "require $parser";
        my $receiver = $self->receiver;
        $receiver = do {
            eval "require $receiver";
            $receiver->new;
        } unless ref $receiver;
        $parser = $parser->new(
            grammar => $self,
            receiver => $receiver,
        );
    }

    return $parser->parse(@_);
}

sub import {
    goto &Pegex::Mo::import
        unless ((caller))[1] =~ /^-e?$/ and @_ == 2 and $_[1] eq 'compile';
    my $package = shift;
    $package->compile_into_module();
    exit;
}

sub compile_into_module {
    my ($package) = @_;
    my $grammar = $package->text;
    my $module = $package;
    $module =~ s!::!/!g;
    $module = "$module.pm";
    my $file = $INC{$module} or return;
    require Pegex::Compiler;
    my $perl = Pegex::Compiler->compile($grammar)->to_perl;
    open IN, $file or die $!;
    my $module_text = do {local $/; <IN>};
    close IN;
    $perl =~ s/^/  /gm;
    $module_text =~ s/^(sub\s+tree_?\s*\{).*?(^\})/$1\n$perl$2/ms;
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

There are 4 properties of a Pegex::Grammar: C<tree>, C<text>, C<parser> and
C<receiver>.

=over

=item tree

This is the data structure containing the compiled grammar for your syntax. It
is usually produced by C<Pegex::Compiler>. You can inline it in the C<tree>
method, or else the C<tree_> method will be called to produce it.

The C<tree_> method will call on Pegex::Compiler to compile the C<text>
property by default. You can define your own C<tree_> method to do override
this behavior.

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

=item parser

This will default to C<Pegex::Parser> and you should probably never need to
change that. It's the Parser class that will handle the work for the
C<parse()> method. If you need to subclass the parser for some reason, you
would set the sublass here.

=item receiver

This will default to C<Pegex::Receiver>. It is the class or object that will
handle all the callbacks from the parser, and do something with them. Usually
it will create a data structure representing the parsed input, but you can
have it do whatever you want. The default receiver creates a fairly messy data
structure with the result of your parse, but subclassing C<TestML::Receiver>
is easy.

You can also set this to a reference of your Grammar object, if you want to
specify all your grammar receiver callbacks inline. You can do that like this
(assuming a Moose compliant subclass):

    has receiver => (
        is => 'ro',
        default => sub { shift },
    );

=back

=head1 METHODS

There is only one public method:

=over

=item parse($input [ , $start_rule ])

The C<parse> method applies the grammar against the text, and tells the
receiver object what is happening as it happens. If the parse fails, an error
is thrown. If it succeeds, then C<parse> returns the data structure created by
the receiver object.

This method is really just a handy proxy for C<Pegex::Parser::parse>. It takes
the same input arguments and produces the same outputs.

The first (required) argument is the input to be parsed. This can be a text
string, a file path, or a L<Pegex::Input> object.

The second (optional) argument is the starting rule name. By default, this is
the first rule specified in the grammar, or the rule named 'TOP' (if present).
