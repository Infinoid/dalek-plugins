package modules::local::parrot_plumagelog;
use strict;
use warnings;
use base 'modules::local::gitoriousparser';


=head1 NAME

    modules::local::parrot_plumageklog

=head1 DESCRIPTION

This is a subclass of modules::local::gitoriousparser.  It adds a parser to
emit parrot-plumage commits.

The parrot-plumage commit messages go to #parrot on magnet.


=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
hands the URL to the gitorious parser module and tells it to emit to magnet's
#parrot.

=cut

my $url = 'http://gitorious.org/parrot-plumage/parrot-plumage';

sub init {
    modules::local::gitoriousparser->try_link($url);
}

1;
