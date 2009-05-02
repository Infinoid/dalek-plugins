#!perl
use strict;
use warnings;

use Test::More;
use Cwd;
use lib getcwd();
use t::util;

# note: the order these are loaded in determine the order of the target channels,
# and thus, the tests below depend on this ordering.
load_plugin("autofeed");
load_plugin("rakudolog");

my $tests;
BEGIN { $tests = 0; };

plan tests => $tests;

my $xml_header = << '__XML__';
<?xml version="1.0" encoding="UTF-8"?>
<feed xml:lang="en-US" xmlns="http://www.w3.org/2005/Atom">
  <id>tag:github.com,2008:/feeds/rakudo/commits/rakudo/master</id>
  <link type="text/html" rel="alternate" href="http://github.com/rakudo/rakudo/commits/master/"/>
  <link type="application/atom+xml" rel="self" href="http://github.com/feeds/rakudo/commits/rakudo/master"/>
  <title>Recent Commits to rakudo:master</title>
__XML__

my $xml_footer = << '__XML__';
  <entry>
    <id>tag:github.com,2008:Grit::Commit/c7d2d7784f80b2c9f05b68d4aa5a6e21a2f2a257</id>
    <link type="text/html" rel="alternate" href="http://github.com/rakudo/rakudo/commit/c7d2d7784f80b2c9f05b68d4aa5a6e21a2f2a257"/>
    <title>Merge branch 'master' of git@github.com:rakudo/rakudo</title>
    <updated>2009-05-01T09:32:55-07:00</updated>
    <content type="html">&lt;pre&gt;
Merge branch 'master' of git@github.com:rakudo/rakudo&lt;/pre&gt;</content>
    <author>
      <name>pmichaud</name>
    </author>
  </entry>
</feed>
__XML__

# initial sync
my $xml = $xml_header . '<updated>2009-05-01T09:32:55-07:00</updated>' . $xml_footer;
my $feed = XML::Atom::Feed->new(\$xml);
my $rl = modules::local::rakudolog->get_self();
ok(!exists($$rl{lastrev}), "no lastrev by default");
call_func('process_feed', $feed);
my $output = [output()];
is(scalar @$output, 0, "nothing output the first time around");
is($$rl{lastrev}, "2009-05-01T09:32:55-07:00", "lastrev was set");
BEGIN { $tests += 3 };

# update
$xml_footer = << '__XML__' . $xml_footer;
  <entry>
    <id>tag:github.com,2008:Grit::Commit/7f5af50c19baf360dacc5779b9c013fb14db34d3</id>
    <link type="text/html" rel="alternate" href="http://github.com/rakudo/rakudo/commit/7f5af50c19baf360dacc5779b9c013fb14db34d3"/>
    <title>Big refactor of Rakudo's enums, making them more compliant with S12, and building them with much less generated code. Track an enum related grammar change from STD.pm too. Also gets rid of various bits of cruft that only hung around because of the previous enums implementation needing them. Bool is no longer sort-of-enum-ish (before we had some curious interactions there). Also an infinite loop in infix:&lt;but&gt; is fixed.</title>
    <updated>2009-05-01T09:58:40-07:00</updated>
    <content type="html">&lt;pre&gt;m src/builtins/enums.pir
m src/builtins/guts.pir
m src/builtins/op.pir
m src/classes/Abstraction.pir
m src/classes/Bool.pir
m src/parser/actions.pm
m src/parser/grammar.pg

Big refactor of Rakudo's enums, making them more compliant with S12, and building them with much less generated code. Track an enum related grammar change from STD.pm too. Also gets rid of various bits of cruft that only hung around because of the previous enums implementation needing them. Bool is no longer sort-of-enum-ish (before we had some curious interactions there). Also an infinite loop in infix:&amp;lt;but&amp;gt; is fixed.&lt;/pre&gt;</content>
    <author>
      <name>jnthn</name>
    </author>
  </entry>
__XML__
$xml = $xml_header . '<updated>2009-05-01T09:58:40-07:00</updated>' . $xml_footer;
$feed = XML::Atom::Feed->new(\$xml);
call_func('process_feed', $feed);
$output = [output()];
is(scalar @$output, 6, "6 lines of output");
is($$output[0]{net} , 'magnet'  , "line to magnet/#parrot");
is($$output[0]{chan}, '#parrot' , "line to magnet/#parrot");
is($$output[1]{net} , 'freenode', "line to freenode/#perl6");
is($$output[1]{chan}, '#perl6'  , "line to freenode/#perl6");
is($$rl{lastrev}, "2009-05-01T09:58:40-07:00", "lastrev was updated");
BEGIN { $tests += 6 };
