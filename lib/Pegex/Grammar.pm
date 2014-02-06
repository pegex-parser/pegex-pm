package Pegex::Grammar;

use Pegex::Base;

# Grammar can be in text or tree form. Tree will be compiled from text.
# Grammar can also be stored in a file.
has file => ();
has text => (
    builder => 'make_text',
    lazy => 1,
);
has tree => (
    builder => 'make_tree',
    lazy => 1,
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
#     require Pegex::Bootstrap;
#     my $perl = Pegex::Bootstrap->new->compile($grammar_text)->to_perl;
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
