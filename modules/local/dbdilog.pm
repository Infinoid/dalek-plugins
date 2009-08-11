package modules::local::dbdilog;
use strict;
use warnings;
use base 'modules::local::googlecodeparser';


=head1 NAME

    modules::local::dbdilog

=head1 DESCRIPTION

This is a subclass of modules::local::googlecodeparser.  It adds a parser to
emit dbdi commits.

DBDI is a project to port the JDBC API from Java to Parrot and use it as a
backend for the new DBI, and for world domination in general. Inititated by
Tim Bunce.


=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
hands the URL to the googlecode parser module.

=cut

my $url = 'http://code.google.com/p/java2perl6/';

sub init {
    modules::local::googlecodeparser->try_link($url, ['freenode', '#dbdi']);
}

1;
