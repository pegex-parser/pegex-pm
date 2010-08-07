package Parse::Pegex;
use strict;
use warnings;
use 5.008003;
use Parse::Pegex::Base -base;

our $VERSION = '0.01';

# has 'grammar', -init => '$self->{grammar_data}';
has 'stream';
has 'rule';
has 'position' => 0;
has 'receiver';
has 'arguments' => [];

sub grammar {
    my $self = shift;
    require Parse::Pegex::Compiler;
    my $compiler = Parse::Pegex::Compiler->new;
    return $compiler->compile($self->grammar_text);
}

sub parse {
    my $self = shift;
    $self->stream(shift);
    $self->init(@_);
    $self->match($self->rule);
    if ($self->position < length($self->stream)) {
        die "Parse document failed for some reason";
    }
    return $self;
}

sub match {
    my $self = shift;
    my $rule = shift or die "No rule passed to match";

    my $not = 0;

    my $state = undef;
    if (not ref($rule) and $rule =~ /^\w+$/) {
        die "\n\n*** No grammar support for '$rule'\n\n"
            unless $self->grammar->{$rule};
        $state = $rule;
        $rule = $self->grammar->{$rule}
    }

    my $method;
    my $times = $rule->{'<'} || '1';
    if ($rule->{'+not'}) {
        $rule = $rule->{'+not'};
        $method = 'match';
        $not = 1;
    }
    elsif ($rule->{'+rule'}) {
        $rule = $rule->{'+rule'};
        $method = 'match';
    }
    elsif (defined $rule->{'+re'}) {
        $rule = $rule->{'+re'};
        $method = 'match_regexp';
    }
    elsif ($rule->{'+all'}) {
        $rule = $rule->{'+all'};
        $method = 'match_all';
    }
    elsif ($rule->{'+any'}) {
        $rule = $rule->{'+any'};
        $method = 'match_any';
    }
    elsif ($rule->{'+error'}) {
        my $error = $rule->{'+error'};
        $self->throw_error($error);
    }
    else {
        require Carp;
        Carp::confess("no support for $rule");
    }

    if ($state and not $not) {
        $self->callback("try_$state");
    }

    my $position = $self->position;
    my $count = 0;
    while ($self->$method($rule)) {
        $count++;
        last if $times eq '1' or $times eq '?';
    }
    my $result = (($count or $times eq '?' or $times eq '*') ? 1 : 0) ^ $not;

    if ($state and not $not) {
        $result
            ? $self->callback("got_$state")
            : $self->callback("not_$state");
        $self->callback("end_$state")
    }

    $self->position($position) unless $result;
    return $result;
}

sub match_all {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) or return 0;
    }
    return 1;
}

sub match_any {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) and return 1;
    }
    return 0;
}

sub match_regexp {
    my $self = shift;
    my $regexp = shift;

    pos($self->{stream}) = $self->position;
    $self->{stream} =~ /$regexp/g or return 0;
    if (defined $1) {
        $self->arguments([$1, $2, $3, $4, $5]);
    }
    $self->position(pos($self->{stream}));

    return 1;
}

my $warn = 0;
sub callback {
    my $self = shift;
    my $method = shift;

    if ($self->receiver->can($method)) {
        $self->receiver->$method(@{$self->arguments});
    }
}

sub throw_error {
    my $self = shift;
    my $msg = shift;
    die $msg;
#     my $line = @{[substr($self->stream, 0, $self->position) =~ /(\n)/g]} + 1;
#     my $context = substr($self->stream, $self->position, 50);
#     $context =~ s/\n/\\n/g;
#     die <<"...";
# Error parsing TestML document:
#   msg: $msg
#   line: $line
#   context: "$context"
# ...
}

1;

=encoding utf-8

=head1 NAME

Parse::Pegex - Pegex Parser Generator

=head1 SYNOPSIS

    package MyParser;
    use Parse::Pegex -base;

=head1 DESCRIPTION

Pegex is a new Acmeist parsing technique.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
