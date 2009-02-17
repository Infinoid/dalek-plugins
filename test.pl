#!/usr/bin/perl
use strict;
use warnings;
use lib "../..";

$ENV{TEST_RSS_PARSER} = 1;

my $module = shift;
unless(defined($module) && -f $module) {
    die("Usage: $0 <modulename.pm>\n");
    exit 1;
}

do $module;
$module =~ s/\.pm$//;
$module = "modules::local::$module";
my $inst = $module;

sub run_function {
    my $function = shift;
    $inst->$function();
}

run_function("init");

sub get_item { "" }
sub store_item {}
sub create_timer {
    my ($timername, $self, $functionname, $timeout) = @_;
    run_function($functionname) for (0..1);
}

my $lastline;
sub send_privmsg {
    my ($network, $channel, $line) = @_;
    # module may output the same line to multiple channels; detect that here.
    return if $line eq $lastline;
    print("CHANNEL: $line\n");
    $lastline = $line;
}

sub lprint {
    my $line = shift;
    print("log: $line\n");
}
