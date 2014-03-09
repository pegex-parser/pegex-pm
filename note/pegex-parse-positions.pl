use Pegex::JSON;
use XXX;

{
    package Pegex::JSON::Data;
    my $got_string;
    BEGIN {
        $got_string = \&Pegex::JSON::Data::got_string;
    }

    use XXX;
    sub got_string {
        my ($receiver, $data) = @_;
        # XXX $receiver;
        print "Got string '$data' at position " .
            "'${\ $receiver->{parser}{position}}'\n";
        $got_string->(@_);

    }
}

XXX + Pegex::JSON->load('{"foo": ["bar", 42]}');
