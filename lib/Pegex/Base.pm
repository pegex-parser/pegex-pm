# Pegex::Base generated from Moos.pm

# The entire implementation of Pegex::Base (and all its related classes)
# are defined inside this one file.
use strict;
use warnings;

package Pegex::Base;
use v5.10.0;
use mro;
use Scalar::Util;

# our $VERSION = '0.05';

sub import {
    # Get name of the "class" from whence "use Pegex::Base;"
    my $package = caller;

    # Turn on strict/warnings for caller
    strict->import;
    warnings->import;

    # Create/register a metaclass object for the package
    my $meta = Pegex::Base::Meta::Class->initialize($package);

    # Make calling class inherit from Pegex::Object by default
    extends($meta, 'Pegex::Object');

    # Export the 'has' and 'extends' helper functions
    _export($package, has => \&has, $meta);
    _export($package, extends => \&extends, $meta);

    # Possibly export some handy debugging stuff
    _export_xxx($package) if $ENV{PERL_PEGEX_XXX};
}

# Attribute generator
sub has {
    my ($meta, $name) = splice(@_, 0, 2);
    my %args;

    # Support 2-arg shorthand: 
    #     has foo => 42;
    if (@_ % 2) {
        my $default = shift;
        my $sub = 
            ref($default) eq 'HASH' ? sub {+{%$default}} :
            ref($default) eq 'ARRAY' ? sub {[@$default]} :
            sub {$default};
        %args = (default => $sub);
    }
    %args = (%args, @_);

    # Add attribute to meta class object
    $meta->add_attribute($name => %args);

    # Make a Setter/Getter accessor
    my ($builder, $default) = @args{qw(builder default)};
    my $accessor =
        $builder ? sub {
            $#_ ? $_[0]{$name} = $_[1] :
            exists($_[0]{$name}) ? $_[0]{$name} :
            ($_[0]{$name} = $_[0]->$builder);
        } :
        $default ? sub {
            $#_ ? $_[0]{$name} = $_[1] :
            exists($_[0]{$name}) ? $_[0]{$name} :
            ($_[0]{$name} = $default->($_[0]));
        } :
        sub {
            $#_ ? $_[0]{$name} = $_[1] : $_[0]{$name};
        };

    # Dev debug thing to trace calls to accessor subs.
    $accessor = _trace_accessor_calls($name, $accessor)
        if $ENV{PERL_PEGEX_ACCESSOR_CALLS};

    # Export the accessor.
    _export($meta->{package}, $name, $accessor);
}

# Inheritance maker
sub extends {
    my ($meta, $parent) = @_;
    eval "require $parent";
    no strict 'refs';
    @{"$meta->{package}\::ISA"} = ($parent);
}

# Use this for exports and meta-exports
sub _export {
    my ($package, $name, $code, $meta) = @_;
    if (defined $meta) {
        my $orig = $code;
        $code = sub {
            unshift @_, $meta;
            goto &$orig;
        };
    }
    no strict 'refs';
    *{"$package\::$name"} = $code;
}

# Export the 4 debugging subs from XXX.pm
sub _export_xxx {
    my ($package) = @_;
    eval "use XXX -with => 'YAML::XS'; 1" or die $@;
    no strict 'refs';
    _export($package, WWW => \&{__PACKAGE__ . '::WWW'});
    _export($package, XXX => \&{__PACKAGE__ . '::XXX'});
    _export($package, YYY => \&{__PACKAGE__ . '::YYY'});
    _export($package, ZZZ => \&{__PACKAGE__ . '::ZZZ'});
}

# A tracing wrapper for debugging accessors
my $trace_exclude = +{
    map {($_, 1)} (
        'Some::Module some_accessor',
        'Some::Module some_other_accessor',
    )
};
sub _trace_accessor_calls {
    require Time::HiRes;
    my ($name, $accessor) = @_;
    sub {
        my ($pkg, $file, $line, $sub) = caller(0);
        unless ($trace_exclude->{"$pkg $name"}) {
            warn "$pkg $name $line\n";
            Time::HiRes::usleep(100000);
        }
        goto &$accessor;
    };
}

# The remainder of this module was heavily inspired by Pegex::Basee, and tried to do
# what Pegex::Basee does, only much less.
package Pegex::Base::Meta::Class;

my $meta_class_objects = {};

sub name { $_[0]->{package} }

sub initialize {
    my ($class, $package) = @_;

    return $meta_class_objects->{$package} //= do {
        bless {
            package => $package,
            attributes => {},
            _attributes => [],
        }, $class;
    };
}

# Make a new attrribute object and add it to both a hash and an array, so that
# we can preserve the order defined.
sub add_attribute {
    my $self = shift;
    my ($name, %args) = @_;
    push @{$self->{_attributes}}, (
        $self->{attributes}{$name} =
            bless {
                name => $name,
                %args,
            }, 'Pegex::Base::Meta::Attribute'
    );
}

sub new_object {
    my ($self, $params) = @_;
    my $object = $self->_construct_instance($params);
    $object->BUILDALL($params) if $object->can('BUILDALL');
    return $object;
}

sub _construct_instance {
    my ($self, $params) = @_;
    my $instance = bless {}, $self->name;
    foreach my $attr ($self->get_all_attributes()) {
        my $name = $attr->{name};
        next if exists $instance->{$name};
        if (exists $params->{$name}) {
            $instance->{$name} = $params->{$name};
            next;
        }
        if (not $attr->{lazy}) {
            if (my $builder = $attr->{builder}) {
                $instance->{$name} = $instance->$builder();
                next;
            }
            elsif (my $default = $attr->{default}) {
                $instance->{$name} = $default->($instance);
            }
        }
    }
    return $instance;
}

sub get_all_attributes {
    my $self = shift;
    my (@attrs, %attrs);
    for my $package (@{mro::get_linear_isa($self->name)}) {
        my $meta = Pegex::Base::Meta::Class->initialize($package);
        for my $attr (@{$meta->{_attributes}}) {
            my $name = $attr->{name};
            next if $attrs{$name};
            push @attrs, ($attrs{$name} = $attr);
        }
    }
    return @attrs;
}

package Pegex::Object;

sub new {
    my $class = shift;
    my $real_class = Scalar::Util::blessed($class) || $class;
    my $params = $real_class->BUILDARGS(@_);
    return Pegex::Base::Meta::Class->initialize($real_class)->new_object($params);
}

sub BUILDARGS {
    return {@_[1..$#_]};
}

sub BUILDALL {
    return unless $_[0]->can('BUILD');
    my ($self, $params) = @_;
    for my $package (
        reverse @{mro::get_linear_isa(Scalar::Util::blessed($self))}
    ) {
        no strict 'refs';
        if (defined &{"$package\::BUILD"}) {
            &{"$package\::BUILD"}($self, $params);
        }
    }
}

sub dump {
    no warnings 'once';
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Maxdepth = shift if @_;
    Data::Dumper::Dumper $self;
}

sub meta {
    Pegex::Base::MOP::Class->initialize(Scalar::Util::blessed($_[0]) || $_[0]);
}

1;

