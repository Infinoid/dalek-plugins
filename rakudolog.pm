package modules::local::rakudolog;
use strict;
use warnings;
use SUPER;
use base qw(modules::local::githubparser);

my $url = 'http://github.com/feeds/rakudo/commits/rakudo/master';

sub init {
    my $self = shift;
    $self = bless({modulename => $self}, $self) unless ref($self);
    $$self{url}       = $url;
    $$self{feed_name} = 'rakudo';
    $$self{targets}   = [
        [ "magnet",   "#parrot" ],
        [ "freenode", "#perl6"  ],
    ];
    my $initfunc = $self->super('init');
    $initfunc->($self);
}

1;
