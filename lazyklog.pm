package modules::local::lazyklog;
use strict;
use warnings;
use SUPER;
use base qw(modules::local::githubparser);

my $url = 'http://github.com/feeds/bschmalhofer/commits/lazy-k/master';

sub init {
    my $self = shift;
    $self = bless({modulename => $self}, $self) unless ref($self);
    $$self{url}              = $url;
    $$self{module_name}      = 'lazy-k';
    $$self{lastrev_var_name} = 'lazyk_lastrev';
    $$self{targets}          = [
        [ "magnet", "#parrot" ],
    ];
    my $initfunc = $self->super('init');
    $initfunc->($self);
}

1;
