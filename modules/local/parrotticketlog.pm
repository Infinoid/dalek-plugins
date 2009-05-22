package modules::local::parrotticketlog;
use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use XML::RAI;
use HTML::Entities;
use WWW::Shorten::Metamark;
use WWW::Shorten 'Metamark';

use base 'modules::local::karmalog';

# Parse RSS generated from trac's "timeline" page (filtered to show only tickets).

my $url  = 'https://trac.parrot.org/parrot/timeline?ticket=on&format=rss';
my $lastrev;
my $copy_of_self;

sub init {
    my $self = shift;
    $copy_of_self = $self;
    main::lprint("parrot ticket RSS parser loaded.");
    main::create_timer("parrotticketlog_fetch_feed_timer", $self, "fetch_feed", 181);
}

sub implements {
    return qw();
}

sub shutdown {
    my $self = shift;
    main::delete_timer("parrotticketlog_fetch_feed_timer");
}

my $lwp = LWP::UserAgent->new();
$lwp->timeout(60);
$lwp->env_proxy();
# upgrade this to an %objects_by_package if this ends up being subclassed.
my $self = bless({ seen => {}, targets => [['magnet','#parrot']] }, __PACKAGE__);
$$self{not_first_time} = 1 if exists $ENV{TEST_RSS_PARSER};

sub fetch_feed {
    my $response = $lwp->get($url);
    if($response->is_success) {
        my $feed = XML::RAI->parse_string($response->content);
        process_feed($feed);
    } else {
        main::lprint("parrotticketlog: fetch_feed: failure fetching $url");
    }
}

sub process_feed {
    my $feed = shift;
    my @items = @{$feed->items};
    @items = sort { $a->created cmp $b->created } @items; # ascending order

    # skip the first run, to prevent new installs from flooding the channel
    foreach my $item (@items) {
        my $rev = $item->identifier;
        if(exists($$self{not_first_time})) {
            # output new entries to channel
            next if exists($$self{seen}{$rev});
            $$self{seen}{$rev} = 1;
            $self->output_item($item);
        } else {
            $$self{seen}{$rev} = 1;
        }
    }
    $$self{not_first_time} = 1;
}


sub output_item {
    my ($self, $item) = @_;
    my $user    = $item->creator;
    my $desc    = $item->title;

    $desc =~ s/<[^>]+>//g;
    $desc =~ s|…|...|g;
    decode_entities($desc);
    if($desc =~ /^Ticket \#(\d+) \((.+)\) (\S+)\s*$/) {
        my ($ticket, $summary, $action) = ($1, $2, $3);
        $self->emit_ticket_karma(
            prefix  => 'TT #',
            ticket  => $ticket,
            action  => $action,
            user    => $user,
            summary => $summary,
            targets => $$self{targets},
        );
        main::lprint("parrotticketlog: ticket $ticket $action");
    } else {
        main::lprint("parrotticketlog: regex failed on $desc");
    }
}

1;
