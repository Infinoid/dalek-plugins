package modules::local::wmlscriptlog;
use strict;
use warnings;
use SUPER;
use base qw(modules::local::githubparser);

my $url = 'http://github.com/feeds/fperrad/commits/wmlscript/master';

sub init {
    my $self = shift;
    $self = bless({modulename => $self}, $self) unless ref($self);
    $$self{url}       = $url;
    $$self{feed_name} = 'wmlscript';
    $$self{targets}   = [
        [ "magnet", "#parrot" ],
    ];
    my $initfunc = $self->super('init');
    $initfunc->($self);
}

1;
