package modules::local::tracwikilog;
use strict;
use warnings;
use LWP::UserAgent;
use XML::RAI;
use HTML::Entities;
use WWW::Shorten::Metamark;
use WWW::Shorten 'Metamark';

# Parse RSS generated from trac's "revision log" page.

my $url  = 'https://trac.parrot.org/parrot/timeline?wiki=on&format=rss';
my $lastrev;
my $copy_of_self;

sub init {
    my $self = shift;
    $copy_of_self = $self;
    main::lprint("tracwiki trac RSS parser loaded.");
    main::create_timer("tracwikilog_fetch_feed_timer", $self, "fetch_feed", 180);
}

sub implements {
    return qw();
}

sub shutdown {
    my $self = shift;
    main::delete_timer("tracwikilog_fetch_feed_timer");
}

my $lwp = LWP::UserAgent->new();
$lwp->timeout(30);
$lwp->env_proxy();

sub fetch_feed {
    my $response = $lwp->get($url);
    if($response->is_success) {
        my $feed = XML::RAI->parse_string($response->content);
        process_feed($feed);
    } else {
        main::lprint("tracwikilog: fetch_feed: failure fetching $url");
    }
}

sub process_feed {
    my $rss = shift;
    my @items = @{$rss->items};
    @items = sort { $a->issued cmp $b->issued } @items; # ascending order
    my $newest = $items[-1];
    my $date   = $newest->issued;
    $date      = $items[0]->issued if exists $ENV{TEST_RSS_PARSER};

    # skip the first run, to prevent new installs from flooding the channel
    if(defined($lastrev)) {
        # output new entries to channel
        foreach my $item (@items) {
            my $this = $item->issued;
            output_item($item) if $this gt $lastrev;
        }
    }
    $lastrev = $date;
}

sub longest_common_prefix {
    my $prefix = shift;
    for (@_) {
        chop $prefix while (! /^\Q$prefix\E/);
    }
    return $prefix;
}


sub output_item {
    my $item = shift;
    my $creator = $item->creator;
    my $link    = $item->link . "&action=diff";
    my ($desc)  = $item->description =~ m|<p>\s*(.*?)\s*</p>|s;
    my ($rev)   = $link =~ /version=(\d+)/;
    my ($page)  = $link =~ m|/parrot/wiki/(.+)\?version=|;

    if(defined($rev)) {
        main::lprint("tracwikilog: output_item: output $page rev $rev");
        put("tracwiki: v$rev | $creator++ | $page");
    } else {
        main::lprint("tracwikilog: output_item: output unversioned item");
        # unversioned update, just output the title as-is.
        my $title = $item->title;
        put("tracwiki: $creator++ | $title");
    }
    if (defined($desc)) {
        $desc =~ s/<.*?>//;
        put("tracwiki: $desc") if ($desc ne "");
    }
    put("tracwiki: $link");
}

sub put {
    my $line = shift;
    main::send_privmsg("magnet", "#parrot", $line);
}

1;
