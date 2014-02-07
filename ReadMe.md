# NAME

Pegex - Acmeist PEG Parser Framework

# SYNOPSIS

    use Pegex;
    my $result = pegex($grammar)->parse($input);

or with options:

    use Pegex;
    use ReceiverClass;
    my $parser = pegex($grammar, 'ReceiverClass');
    my $result = $parser->parse($input);

or more explicitly:

    use Pegex::Parser;
    use Pegex::Grammar;
    my $pegex_grammar = Pegex::Grammar->new(
        text => $grammar,
    );
    my $parser = Pegex::Parser->new(
        grammar => $pegex_grammar,
    );
    my $result = $parser->parse($input);

or customized explicitly:

    {
        package MyGrammar;
        use Pegex::Base;
        extends 'Pegex::Grammar';
        has text => "your grammar definition text goes here";
        has receiver => "MyReceiver";
    }
    {
        package MyReceiver;
        use base 'Pegex::Receiver';
        got_some_rule { ... }
        got_other_rule { ... }
    }
    use Pegex::Parser;
    my $parser = Pegex::Parser->new(
        grammar => MyGrammar->new,
        receiver => MyReceiver->new,
    );
    $parser->parse($input);
    my $result = $parser->receiver->data;

# DESCRIPTION

Pegex is a Acmeist parser framework. It allows you to easily create parsers
that will work equivalently in lots of programming languages!

Pegex gets it name by combining Parsing Expression Grammars (PEG), with
Regular Expessions (Regex). That's actually what Pegex does.

PEG is the cool new way to elegantly specify recursive descent grammars. The
Perl 6 language is defined in terms of a self modifying PEG language called
__Perl 6 Rules__. Regexes are familiar to programmers of most modern
programming languages. Pegex defines a simple PEG syntax, where all the
terminals are regexes. This means that Pegex can be quite fast and powerful.

Pegex attempts to be the simplest way to define new (or old) Domain Specific
Languages (DSLs) that need to be used in several programming languages and
environments.

# USAGE

The `Pegex.pm` module itself (this module) is just a trivial way to use the
Pegex framework. It is only intended for the simplest of uses.

This module exports a single function, `pegex`, which takes a Pegex grammar
string as input. You may also pass a receiver class name after the grammar.

    my $parser = pegex($grammar, 'MyReceiver');

The `pegex` function returns a [Pegex::Parser](http://search.cpan.org/perldoc?Pegex::Parser) object, on which you would
typically call the `parse()` method, which (on success) will return a data
structure of the parsed data.

See [Pegex::API](http://search.cpan.org/perldoc?Pegex::API) for more details.

# SEE ALSO

- [Pegex::Overview](http://search.cpan.org/perldoc?Pegex::Overview)
- [Pegex::API](http://search.cpan.org/perldoc?Pegex::API)
- [Pegex::Syntax](http://search.cpan.org/perldoc?Pegex::Syntax)
- [Pegex::Tutorial](http://search.cpan.org/perldoc?Pegex::Tutorial)
- [Pegex::Resources](http://search.cpan.org/perldoc?Pegex::Resources)
- [http://github.com/ingydotnet/pegex-pm](http://github.com/ingydotnet/pegex-pm)
- [irc.freenode.net\#pegex](http://search.cpan.org/perldoc?irc.freenode.net\#pegex)

# AUTHOR

Ingy döt Net <ingy@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011, 2012, 2013. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
