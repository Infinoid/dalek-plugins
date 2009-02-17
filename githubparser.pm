package modules::local::githubparser;
use strict;
use warnings;
use XML::Atom::Client;
use HTML::Entities;

# Parse ATOM generated by github.com.

my $feed_number = 1;

my %objects_by_package;

sub init {
    my $self = shift;
    my $package_name = $$self{modulename};
    my $feed_name    = $$self{feed_name};
    $objects_by_package{$package_name} = $self;
    main::lprint("$feed_name github ATOM parser loaded.");
    main::create_timer($feed_name."_fetch_feed_timer", $$self{modulename},
        "fetch_feed", 180 + $feed_number++);
}

sub implements {
    return qw();
}

sub shutdown {
    my $pkg = shift;
    my $self = $objects_by_package{$pkg};
    main::delete_timer($$self{feed_name}."_fetch_feed_timer");
}

sub fetch_feed {
    my $pkg  = shift;
    my $self = $objects_by_package{$pkg};
    my $atom = XML::Atom::Client->new();
    my $feed = $atom->getFeed($$self{url});
    $self->process_feed($feed);
}

sub process_feed {
    my ($self, $feed) = @_;
    my @items = $feed->entries;
    @items = sort { $a->updated cmp $b->updated } @items; # ascending order
    my $newest = $items[-1];
    my $latest = $newest->updated;
    $latest = $items[0]->updated if exists $ENV{TEST_RSS_PARSER};

    # skip the first run, to prevent new installs from flooding the channel
    if(defined($$self{lastrev})) {
        # output new entries to channel
        foreach my $item (@items) {
            my $updated = $item->updated;
            $self->output_item($item) if $updated gt $$self{lastrev};
        }
    }
    $$self{lastrev} = $latest;
}

sub longest_common_prefix {
    my $prefix = shift;
    for (@_) {
        chop $prefix while (! /^\Q$prefix\E/);
    }
    return $prefix;
}


sub output_item {
    my ($self, $item) = @_;
    my $prefix  = 'unknown';
    my $creator = $item->author;
    if(defined($creator)) {
        $creator = $creator->name;
    } else {
        $creator = 'unknown';
    }
    my $link    = $item->link->href;
    my $desc    = $item->content;
    if(defined($desc)) {
        $desc = $desc->body;
    } else {
        $desc = '(no commit message)';
    }

    $creator = "($creator)" if($creator =~ /\s/);

    my ($rev)   = $link =~ m|/commit/([a-z0-9]{40})|;
    my ($log, $files);
    $desc =~ s/^.*<pre>//;
    $desc =~ s/<\/pre>.*$//;
    my @lines = split("\n", $desc);
    my @files;
    while($lines[0] =~ /^m (.+)/) {
        push(@files, $1);
        shift(@lines);
    }
    return main::lprint($$self{feed_name}.": error parsing filenames from description")
        unless $lines[0] eq '';
    shift(@lines);
    pop(@lines) if $lines[-1] =~ /^git-svn-id: http:/;
    pop(@lines) while scalar(@lines) && $lines[-1] eq '';
    $log = join("\n", @lines);

    $prefix =  longest_common_prefix(@files);
    $prefix =~ s|^/||;      # cut off the leading slash
    if(scalar @files > 1) {
        $prefix .= " (" . scalar(@files) . " files)";
    }

    $log =~ s|<br */>||g;
    decode_entities($log);
    my @log_lines = split(/[\r\n]+/, $log);

    $rev = substr($rev, 0, 7);
    $self->put($$self{feed_name}.": $rev | $creator++ | $prefix:");
    foreach my $line (@log_lines) {
	$self->put($$self{feed_name}.": $line");
    }
    $self->put($$self{feed_name}.": review: $link");
    main::lprint($$self{feed_name}.": output_item: output rev $rev");
}

sub put {
    my ($self, $line) = @_;
    foreach my $target (@{$$self{targets}}) {
        main::send_privmsg(@$target, $line);
    }
}

1;
