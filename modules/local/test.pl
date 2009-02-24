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

my $output_anything = 0;

sub run_function {
    my $function = shift;
    $output_anything = 0;
    $inst->$function();
}

run_function("init");

sub create_timer {
    my ($timername, $self, $functionname, $timeout) = @_;
    $output_anything = 1;
    run_function($functionname);
    $output_anything = 1;
    run_function($functionname) while $output_anything;
}

my $lastline;
sub send_privmsg {
    my ($network, $channel, $line) = @_;
    $output_anything = 1;
    # module may output the same line to multiple channels; detect that here.
    if(defined($lastline) && ($line eq $lastline)) {
        return;
    }
    print("CHANNEL: $line\n");
    $lastline = $line;
}

sub lprint {
    my $line = shift;
    print("log: $line\n");
}
