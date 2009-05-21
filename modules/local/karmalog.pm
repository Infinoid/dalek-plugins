package modules::local::karmalog;
use strict;
use warnings;

use LWP::UserAgent;

my $url = 'https://svn.parrot.org/parrot/trunk/CREDITS';

=head1 NAME

    modules::local::karmalog

=head1 DESCRIPTION

This is a base class which knows how to emit karma messages to an IRC channel.

This plugin scrapes the CREDITS file from the Parrot svn repository, and builds
up a hash mapping aliases to usernames.  This is so it can consolidate karma
onto a user's IRC nick, even though their commit bits in various places may be
under different names.

It looks for N: and A: lines in the CREDITS file.  The A: line is something we
just made up, and it stands for "alias" or "AKA".  For the following entry:

    N: Will "Coke" Coleda
    U: coke
    A: wcoleda
    E: will@coleda.com
    D: Tcl language (partcl), APL, website, various languages/ upkeep, misc.

It should understand that commits under the username "wcoleda" are aliased to
"coke", and the irc message should say coke++, not wcoleda++.

=head1 METHODS

=head2 init

This is a pseudo-method called by botnix when the module is first loaded.  It
starts the ball rolling.  This method has two effects:

    * Scans the CREDITS file once.
    * Starts a timer thread which rescans again, once every 3 hours.

=cut

sub init {
    my $self = shift;
    $self->scrape_credits();
    main::create_timer('scrape_CREDITS', $self, 'scrape_credits', 60*60*3);
}


=head2 scrape_credits

    $self->scrape_credits();

Grab the CREDITS file, call parse_credits() with the result.

=cut

sub scrape_credits {
    my $package = shift;
    my $credits = $package->fetch_url($url);
    $package->parse_credits($credits) if defined $credits;
}


=head2 parse_credits

    $self->parse_credits($creditsfile);

Given the contents of the CREDITS file, parse it to an array of hashes, then
extract aliases from that.  The resulting aliases are stored in %aliases.

It expects to find user entries between the leading "----------" and the
trailing "=cut".

This function is separate from scrape_credits so that the testsuite can call
it directly.

=cut

our %aliases;

sub parse_credits {
    my ($package, $credits) = @_;
    my @content = split(/\n/, $credits);
    my $line = '';
    $line = shift(@content) until $line =~ /----------/;
    my $this = {};
    my @entries = $this;

    # parse the file into field structures
    while($line !~ /=cut/) {
        # simple state machine.
        $line = shift(@content);
        if($line =~ /^([A-Z]):\s+(.+)/) {
            my ($type, $value) = ($1, $2);
            $$this{$type} = $value;
        }
        if(!length($line)) {
            # a new user entry is starting
            $this = {};
            push(@entries, $this);
        }
    }

    # find aliases
    my %newaliases;
    foreach my $entry (@entries) {
        next unless exists $$entry{U};
        my $username = $$entry{U};
        $newaliases{$$entry{N}} = $username if exists $$entry{N};
        if(exists($$entry{A})) {
            my @aliases = split(/,\s*/,$$entry{A});
            foreach my $alias (@aliases) {
                $alias =~ s/^"?(.+?)"?$/$1/; # strip leading and trailing quotes
                $newaliases{$alias} = $$entry{U};
            }
        }
    }
    main::lprint("karmalog: aliases file parsed, " . scalar(keys %newaliases) . " aliases total");
    %aliases = %newaliases;
}


=head2 emit_karma_message

    $self->emit_karma_message(
        feed    => $feedname,
        rev     => $rev,
        user    => $username,
        log     => \@log,
        link    => $link,
        prefix  => $prefix,
        targets => $targets,
    );

Emit a log message about a commit to the target channels.  This is the method
the subclasses care about.  Username aliases are handled internally.

The message looks like:

feedname: rev | username++ | prefix
feedname: One or more lines of commit log message
feedname: review: http://link/to/googlecode/diff/page

=cut

sub emit_karma_message {
    my ($self, %args) = @_;
    my $user = $args{user};
    my $feed = $args{feed};
    my $rev  = $args{rev};
    my $end  = $args{prefix};
    $user = "unknown" unless defined $user;
    $user = $aliases{$user} if exists $aliases{$user};
    $user = "($user)" if $user =~ / /;
    $end  = "/" unless defined $end;
    $end .= ':' if(defined($args{log}) || defined($args{link}));
    $self->put($args{targets}, "$feed: $rev | $user++ | $end");
    if(defined($args{log})) {
        foreach my $line (@{$args{log}}) {
            $self->put($args{targets}, "$feed: $line");
        }
    }
    $self->put($args{targets}, "$feed: review: " . $args{link})
        if defined $args{link};
}


=head2 emit_ticket_karma

    $self->emit_ticket_karma(
        prefix  => 'TT #',
        ticket  => $ticket,
        user    => $username,
        summary => $summary,
        action  => 'closed',
    );

Emit a short log message about a ticket change to the target channels.  Username
aliases are handled internally.

The message looks like:

TT #699 closed by jkeenan++: manifest_tests Makefile target does not work in release tarball

=cut

sub emit_ticket_karma {
    use YAML::Syck;
    my ($self, %args) = @_;
    my $prefix  = $args{prefix};
    my $ticket  = $args{ticket};
    my $user    = $args{user};
    my $summary = $args{summary};
    my $action  = $args{action};
    $user       = "unknown"  unless defined $user;
    $summary    = ""         unless defined $summary;
    $prefix     = "Ticket #" unless defined $prefix;
    $user       = $aliases{$user} if exists $aliases{$user};
    $self->put($args{targets}, "$prefix$ticket $action by $user++: $summary");
}


=head2 put

    $self->put($targets, $line);

Output a line of text to the specified list of targets.

=cut

sub put {
    my ($self, $targets, $line) = @_;
    foreach my $target (@$targets) {
        main::send_privmsg(@$target, $line);
    }
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
