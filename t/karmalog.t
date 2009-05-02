#!perl
use strict;
use warnings;

use Test::More;
use Cwd;
use lib getcwd();
use t::util;

# this configures the partcl feed, among others.
load_plugin("karmalog");

my $tests;
BEGIN { $tests = 0; };

plan tests => $tests;

my $creditsfile = << '__CREDITS__';
=pod

Blah blah blah.

Header stuff is ignored.

N: Header Stuff
U: header1
A: header2

----------

N: William Shatner
U: bills
A: bill, James T. Kirk, jim, "James Tiberius Kirk"

N: DeForest Kelley
U: dk
A: Dr. Leonard "Bones" McCoy, "Leonard McCoy", bones, doc, not an engineer

=cut

Footer stuff is ignored.

N: Footer Stuff
U: footer1
A: footer2


__CREDITS__

# parsing
modules::local::karmalog->parse_credits($creditsfile);
my $aref;
{ no warnings 'once'; $aref = \%modules::local::karmalog::aliases; }
is($$aref{bill}, 'bills', "barewords in A: field are parsed");
is($$aref{'James Tiberius Kirk'}, 'bills', "external quotes in A: record are stripped");
is($$aref{'Dr. Leonard "Bones" McCoy'}, 'dk', "internal quotes in A: record are not stripped");
is($$aref{'William Shatner'}, 'bills', "N: field is parsed");
is($$aref{header2}, undef, "A: record of header is ignored");
is($$aref{'Header Stuff'}, undef, "N: record of header is ignored");
is($$aref{footer2}, undef, "footer is ignored too");
BEGIN { $tests += 7 };

# basic emitting
reset_output();
modules::local::karmalog->emit_karma_message(
    rev     => 'abc123',
    user    => 'foo',
    feed    => 'test',
    targets => [['magnet', '#parrot']],
    prefix  => '/',
);
my $output = [output()];
is(scalar @$output, 1, "1 line of output");
is($$output[0]{net} , 'magnet'  , "line to magnet/#parrot");
is($$output[0]{chan}, '#parrot' , "line to magnet/#parrot");
is($$output[0]{text}, 'test: abc123 | foo++ | /', 'single-line output looks normal');
BEGIN { $tests += 4 };

# same thing with log and link and multi-word username
reset_output();
modules::local::karmalog->emit_karma_message(
    rev     => 'abc124',
    user    => 'Foo Bar',
    feed    => 'test',
    targets => [['magnet', '#parrot']],
    prefix  => '/',
    log     => ['line 1', 'line 2'],
    link    => 'http://www.foo.bar/?rev=abc124'
);
$output = [output()];
is(scalar @$output, 4, "4 lines of output");
foreach my $line (0..3) {
    is($$output[$line]{net} , 'magnet'  , "line to magnet/#parrot");
    is($$output[$line]{chan}, '#parrot' , "line to magnet/#parrot");
}
is($$output[0]{text}, 'test: abc124 | (Foo Bar)++ | /:', 'first line looks fine');
is($$output[1]{text}, 'test: line 1', 'log line 1 looks fine');
is($$output[2]{text}, 'test: line 2', 'log line 2 looks fine');
is($$output[3]{text}, 'test: review: http://www.foo.bar/?rev=abc124', 'link line looks fine');
BEGIN { $tests += 13 };
