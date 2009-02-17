package modules::local::perklog;
use strict;
use warnings;
use SUPER;
use base qw(modules::local::githubparser);

my $url = 'http://github.com/feeds/chrisdolan/commits/perk/master';

sub init {
    my $self = shift;
    $self = bless({modulename => $self}, $self) unless ref($self);
    $$self{url}              = $url;
    $$self{module_name}      = 'perk';
    $$self{targets}          = [
        [ "magnet", "#parrot" ],
    ];
    my $initfunc = $self->super('init');
    $initfunc->($self);
}

1;
