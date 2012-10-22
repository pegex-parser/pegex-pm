# Pegex::Base generated from Moos.pm

use strict;
use warnings;

package Pegex::Base;

# our $VERSION = '0.03';

sub import {
    my $caller = caller;
    no strict 'refs';
    no warnings 'once';
    strict->import;
    warnings->import;
    ${"$caller\::__meta"} = { has => [] };
    *{"$caller\::has"} = sub {
        my ($name, %args) = @_;
        my $meta = ${"$caller\::__meta"};
        push @{$meta->{has}}, [$name, \%args];
        my ($builder, $default) = @args{qw(builder default)};

        my $method =
            $builder ? sub {
                $#_ ? $_[0]{$name} = $_[1] :
                exists($_[0]{$name}) ? $_[0]{$name} :
                ($_[0]{$name} = $_[0]->$builder);
            } :
            $default ? sub {
                $#_ ? $_[0]{$name} = $_[1] :
                exists($_[0]{$name}) ?  $_[0]{$name} :
                ($_[0]{$name} = $default->(@_));
            } :
            sub {
                $#_ ? $_[0]{$name} = $_[1] :
                $_[0]{$name};
            };

        $method = trace_accessor_calls($name, $method)
            if $ENV{PERL_PEGEX_ACCESSOR_CALLS};

        *{"$caller\::$name"} = $method;
    };
    *{"$caller\::extends"} = sub {
        eval "require $_[0]";
        @{"$caller\::ISA"} = $_[0];
    },
    @{"$caller\::ISA"} = ('Pegex::Object');

    export_xxx($caller) if $ENV{PERL_PEGEX_XXX};
}

sub export_xxx {
    my ($caller) = @_;
    eval "use XXX -with => 'YAML::XS'; 1" or die $@;
    no strict 'refs';
    *{"$caller\::WWW"} = \&{__PACKAGE__ . '::WWW'};
    *{"$caller\::XXX"} = \&{__PACKAGE__ . '::XXX'};
    *{"$caller\::YYY"} = \&{__PACKAGE__ . '::YYY'};
    *{"$caller\::ZZZ"} = \&{__PACKAGE__ . '::ZZZ'};
}

my $trace_exclude = +{
    map {($_, 1)} (
#         'Some::Module some_accessor',
#         'Some::Module some_other_accessor',
    )
};
sub trace_accessor_calls {
    require Time::HiRes;
    my ($name, $accessor) = @_;
    sub {
        my ($pkg, $file, $line, $sub) = caller(0);
        unless ($trace_exclude->{"$pkg $name"}) {
            warn "$pkg $name $line\n";
#             Time::HiRes::usleep(100000);
        }
        goto &$accessor;
    };
}

package Pegex::Object;

sub new {
    my $self = bless {@_[1..$#_]}, $_[0];
    no strict 'refs';
    for my $class (@{[@{"$_[0]::ISA"}, $_[0]]}) {
        if (defined &{"$class\::BUILD"}) {
            &{"$class\::BUILD"}($self);
        }
    }
    return $self;
}

sub BUILD {
    no strict 'refs';
    my $meta = ${ref($_[0]) . "::__meta"};
    for my $has (@{$meta->{has}}) {
        my ($name, $args) = @$has;
        next if exists $_[0]->{$name} || $args->{lazy};
        if (my $default = $args->{default}) {
            $_[0]->{$name} = $default->($_[0]);
        }
        elsif (my $builder = $args->{builder}) {
            $_[0]->{$name} = $_[0]->$builder();
        }
    }
    return;
}

1;

