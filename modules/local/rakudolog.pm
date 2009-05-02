package modules::local::rakudolog;
use strict;
use warnings;
use SUPER;
use base 'modules::local::githubparser';


=head1 NAME

    modules::local::rakudolog

=head1 DESCRIPTION

This is a subclass of modules::local::githubparser.  It adds a parser to emit
rakudo commits.

Normally rakudo commits are configured automatically by
modules::local::autofeed.  However, that autoconfig sends the messages to
magnet's #parrot, whereas we want rakudo commits to go to freenode's #perl6 as
well.


=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
hands the URL to the github parser module and tells it to emit to freenode's
#perl6.  (If a rakudo parser was already configured, it will consolidate the
config and simply add the freenode channel to the list of targets.)

=cut

my $url = 'http://github.com/rakudo/rakudo';

sub init {
    modules::local::githubparser->try_link($url, ['freenode', '#perl6']);
}

1;
