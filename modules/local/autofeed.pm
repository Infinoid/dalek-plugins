package modules::local::autofeed;
use strict;
use warnings;

use LWP::UserAgent;

use modules::local::githubparser;
use modules::local::gitoriousparser;
use modules::local::googlecodeparser;
#use modules::local::tracparser;
#use modules::local::bitbucketparser;

my @url = (
    'https://trac.parrot.org/parrot/wiki/Languages',
    'https://trac.parrot.org/parrot/wiki/Modules',
);

=head1 NAME

    modules::local::autofeed

=head1 DESCRIPTION

Botnix plugin to scrape the list of Parrot languages and automatically set up
rss/atom feed parsers for recognised hosting services.

This plugin scrapes the list of Parrot languages from the Parrot wiki,
the pages named "Languages" and "Modules".  It then searches for links to
well-known source repository hosting services (currently github, google code
and gitorious) and sets up feed parsers for them automatically.  The resulting
parsers emit karma messages to #parrot on MagNET.

=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
starts the ball rolling.  This method has two effects:

    * Scans the lists of languages and modules once.
    * Starts a timer thread which rescans again, once every hour.

=cut

sub init {
    my $self = shift;
    $self->scrape_pages();
    main::create_timer('autofeed_timer', $self, 'scrape_pages', 60*60);
}


=head2 scrape_pages

    $self->scrape_pages();

Grab the pages, scans them for links in the first column of the table.  For
each link it finds, the try_link() method is called to determine whether the
link is relevant.

Note, this is not currently doing an XML search, it is doing a substring search.
I could break it down into a hash tree using XML::TreePP and then enumerate
the rows in $$ref{html}{body}{div}[2]{div}[1]{div}{table}, but the result would
be brittle and would break if anyone added another paragraph before the table,
or changed the trac theme.

If anyone else knows a way to search for a data pattern at dynamic locations in
the xml tree, please feel free to replace this code.  It's not very big, I
promise.

=cut

sub scrape_pages {
    my $package = shift;
    foreach my $url (@url) {
        my $content = $package->fetch_url($url);
        next unless defined $content;
        # this is nasty but straight-forward.
        my @links = split(/<tr[^>]*><td[^>]*><a(?: class=\S+) href="/, $content);
        shift @links;
        foreach my $link (@links) {
            if($link =~ /^(http[^"]+)"/) {
                $package->try_link($1);
            }
        }
    }
}


=head2 try_link

    $self->try_link($url);

Figure out if the URL is to something worthwile.  Calls the parser modules to
do the dirty work.

=cut

sub try_link {
    my ($package, $url) = @_;
    return modules::local::githubparser->try_link($url) if $url =~ /github/;
    return modules::local::gitoriousparser->try_link($url) if $url =~ /gitorious/;
    return modules::local::googlecodeparser->try_link($url) if $url =~ /google/;
}


=head2 fetch_url

    my $pagedata = $self->fetch_url($url);

Fetch the data using a 30 second timeout.  Return undef if an error or timeout
was encountered.

=cut

my $lwp = LWP::UserAgent->new();
$lwp->timeout(10);
$lwp->env_proxy();

sub fetch_url {
    my ($self, $url) = @_;
    my $response = $lwp->get($url);
    if($response->is_success) {
        return $response->content;
    }
    main::lprint("autofeed: fetch_url: failure fetching $url");
    return undef;
}


=head2 implements

This is a pseudo-method called by botnix to determine which event callbacks
this module supports.  Returns an empty array.

=cut

sub implements {
    return qw();
}

1;
