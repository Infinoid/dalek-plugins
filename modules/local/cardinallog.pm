package modules::local::cardinallog;
use strict;
use warnings;
use base 'modules::local::githubparser';


=head1 NAME

    modules::local::cardinallog

=head1 DESCRIPTION

This is a subclass of modules::local::githubparser.  It adds a parser to emit
cardinal commits.

Treed++ requested that cardinal commits be emitted to #cardinal.  So here it is.


=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
hands the URL to the github parser module and tells it to emit to magnet's
#cardinal.  (If a grok parser was already configured, it will consolidate the
config and simply add the cardinal channel to the list of targets.)

=cut

my $url = 'http://github.com/cardinal/cardinal/';

sub init {
    modules::local::githubparser->try_link($url, ['magnet', '#cardinal']);
}

1;
