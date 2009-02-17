package modules::local::pipplog;
use strict;
use warnings;
use SUPER;
use base qw(modules::local::githubparser);

my $url = 'http://github.com/feeds/bschmalhofer/commits/pipp/master';

sub init {
    my $self = shift;
    $self = bless({modulename => $self}, $self) unless ref($self);
    $$self{url}              = $url;
    $$self{module_name}      = 'pipp';
    $$self{targets}          = [
        [ "magnet", "#parrot" ],
    ];
    my $initfunc = $self->super('init');
    $initfunc->($self);
}

1;
