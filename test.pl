#!/usr/bin/perl
use strict;
use warnings;

$ENV{TEST_RSS_PARSER} = 1;

my $module = shift;
unless(defined($module) && -f $module) {
    die("Usage: $0 <modulename.pm>\n");
    exit 1;
}

do $module;
$module =~ s/\.pm$//;
$module = "modules::local::$module";

sub run_function {
    undef $@;
    my $function = shift;
    $function = $module."::".$function."();";
    eval $function;
    warn($@) if length $@;
}

run_function("init");

sub get_item { "" }
sub store_item {}
sub create_timer {
    my ($timername, $self, $functionname, $timeout) = @_;
    run_function($functionname) for (0..1);
}

sub send_privmsg {
    my ($network, $channel, $line) = @_;
    print("CHANNEL: $line\n");
}
sub lprint {
    my $line = shift;
    print("log: $line\n");
}
