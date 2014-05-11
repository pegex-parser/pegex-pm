use strict;
use Pegex;
use XXX;

{
    package TokenReceiver;
    use base 'Pegex::Tree';
    use XXX;

    my %tokens = (
        true => 1,
        false => 0,
        love => '',
        hate => '',
        bliss => '',
    );

    sub gotrule {
        my ($self, $got) = @_;
        return $got if ref $got;
        my $token = lc($got);
        if (exists $tokens{$token}) {
            my $value = $tokens{$token};
            return(length($value) ? $value : $token);
        }
        return $got->[0];
    }
}

my $grammar = <<'...';
expr: token+
token: /~(<WORD>+)~/
...

XXX pegex($grammar, 'TokenReceiver')->parse("LOVE true hate FALSE");
