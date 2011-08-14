package Pegex::Receiver;
use Mouse;

has data => (is => 'rw', default => sub{+{}});

1;
