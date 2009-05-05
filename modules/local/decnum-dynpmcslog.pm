package modules::local::decnum_dynpmcslog;
use strict;
use warnings;
use base 'modules::local::googlecodeparser';


=head1 NAME

    modules::local::decnumlog

=head1 DESCRIPTION

This is a subclass of modules::local::googlecodeparser.  It adds a parser to
emit decnum-dynpmcs commits.

Decnum-dynpmcs is a GSoC project which darbelo++ is working on, and cotto++ is
mentoring.  It's not a language so it isn't on the Languages page, but we still
want to track its progress.


=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
hands the URL to the googlecode parser module.

=cut

my $url = 'http://code.google.com/p/decnum-dynpmcs/';

sub init {
    modules::local::googlecodeparser->try_link($url);
}

1;
