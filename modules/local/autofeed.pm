package modules::local::autofeed;
use strict;
use warnings;

use LWP::UserAgent;
use JSON;

use modules::local::githubparser;
use modules::local::gitoriousparser;
use modules::local::googlecodeparser;
#use modules::local::tracparser;
#use modules::local::bitbucketparser;

my @scrape = (
    'https://trac.parrot.org/parrot/wiki/Languages',
    'https://trac.parrot.org/parrot/wiki/Modules',
);

# Note: Please make sure you put links to raw JSON files here, not the pretty
# html versions that github generates.
my @json = (
    'http://github.com/perl6/mu/raw/master/misc/dalek-conf.json',
);

=head1 NAME

    modules::local::autofeed

=head1 DESCRIPTION

Botnix plugin to scrape the list of Parrot languages and automatically set up
rss/atom feed parsers for recognised hosting services.

This plugin scrapes a few web pages to find feeds to monitor.

Two Parrot pages are scraped:

    https://trac.parrot.org/parrot/wiki/Languages
    https://trac.parrot.org/parrot/wiki/Modules

And one perl6 page is parsed as JSON:

    http://github.com/perl6/mu/raw/master/misc/dalek-conf.json

For any links it finds in those, it sees whether it can recognize any of them
as well-known source repository hosting services (currently github, google code
and gitorious).  Any links it recognises, it sets up feed parsers for them
automatically.  The JSON parser has the additional benefit of being able to
specify which networks/channels it should output to, and optionally which
branches to monitor (for github only, at present).  For the other two scraped
pages, the resulting parsers emit karma messages to #parrot on MagNET, and for
git repos, the "master" branch is always used.

=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
starts the ball rolling.  This method has two effects:

    * Scans for links once.
    * Starts a timer thread which rescans again, once every hour.

=cut

sub init {
    my $self = shift;
    $self->recheck_pages();
    main::create_timer('autofeed_timer', $self, 'recheck_pages', 60*60);
}


=head2 recheck_pages

    $self->recheck_pages();

This calls scrape_pages and parse_pages to parse URLs from html and from json,
respectively.  This is the top level timer callback function.

=cut

sub recheck_pages {
    my $package = shift;
    $package->parse_pages();
    $package->scrape_pages();
}


=head2 parse_pages

    $self->parse_pages();

This function parses JSON feed pages, and calls try_link on the links it
discovers.  The JSON may specify which networks/channels to output on, and/or
which branches to track.

This is the preferred mechanism of discovering feed links.  The scrape_pages
function (see below) is its predecessor, which I would like to phase out at
some point.

The expected JSON format looks like this:

    [
        {
            "url" : "http://github.com/perl6/mu/",
            "channels": [ ["freenode", "#perl6"] ],
            "branches": ["master", "ng"]
        },
        {
            "url" : "http://github.com/perl6/roast/",
            "channels": [
                ["freenode", "#perl6"]
            ]
        }
    ]

The "channels" and "branches" fields are optional.  If not specified, their
defaults are ["magnet","#parrot"] and ["master"], respectively.  The "url"
field is mandatory.  Any other fields are ignored at present.

=cut

sub parse_pages {
    my $package = shift;
    foreach my $link (@json) {
        my $content = $package->fetch_url($link);
        next unless defined $content;
        my $json;
        eval { $json = decode_json($content); };
        next unless defined $json;
        foreach my $item (@$json) {
            my $channels = ['magnet','#parrot'];
            my $branches = ['master'];
            my $url      = $$item{url};
            $channels = $$item{channels} if exists $$item{channels};
            $branches = $$item{branches} if exists $$item{branches};
            next unless defined $url;
            next unless scalar $channels;
            next unless scalar $branches;
            foreach my $channel (@$channels) {
                $package->try_link($url, $channel, $branches);
            }
        }
    }
}


=head2 scrape_pages

    $self->scrape_pages();

This function scrapes feed links from HTML (trac wiki) pages.  It grabs the
pages, scans them for links in the first column of the table.  For each link
it finds, the try_link() method is called to determine whether the link is
relevant.

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
    foreach my $url (@scrape) {
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

    $self->try_link($url, $target, $branches);

Figure out if the URL is to something worthwile.  Calls the parser modules to
do the dirty work.  If target and branches are specified, those are passed
through as well.  (Note: only the github parser supports the "branches" field
at present.  The field is ignored for other targets.)

=cut

sub try_link {
    my ($package, $url, $target, $branches) = @_;
    return modules::local::githubparser->try_link($url, $target, $branches) if $url =~ /github/;
    # "branches" argument not currently supported for gitorious and googlecode.
    return modules::local::gitoriousparser->try_link($url, $target) if $url =~ /gitorious/;
    return modules::local::googlecodeparser->try_link($url, $target) if $url =~ /google/;
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
