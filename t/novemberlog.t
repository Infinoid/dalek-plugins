#!perl
use strict;
use warnings;

use Test::More;
use Cwd;
use lib getcwd();
use t::util;

load_plugin("novemberlog");

my $tests;
BEGIN { $tests = 0; };

plan tests => $tests;

my $xml_header = << '__XML__';
<?xml version="1.0" encoding="UTF-8"?>
<feed xml:lang="en-US" xmlns="http://www.w3.org/2005/Atom">
  <id>tag:github.com,2008:/feeds/viklund/commits/november-wiki/master</id>
  <link type="text/html" rel="alternate" href="http://github.com/viklund/november-wiki/commits/master/"/>
  <link type="application/atom+xml" rel="self" href="http://github.com/feeds/viklund/commits/november-wiki/master"/>
  <title>Recent Commits to november-wiki:master</title>
__XML__

my $xml_footer = << '__XML__';
  <entry>
    <id>tag:github.com,2008:Grit::Commit/c7d2d7784f80b2c9f05b68d4aa5a6e21a2f2a257</id>
    <link type="text/html" rel="alternate" href="http://github.com/viklund/november-wiki/commit/c7d2d7784f80b2c9f05b68d4aa5a6e21a2f2a257"/>
    <title>Merge branch 'master' of git@github.com:viklund/november-wiki</title>
    <updated>2009-05-01T09:32:55-07:00</updated>
    <content type="html">&lt;pre&gt;
Merge branch 'master' of git@github.com:viklund/november-wikilt;/pre&gt;</content>
    <author>
      <name>pmichaud</name>
    </author>
  </entry>
</feed>
__XML__

# initial sync
my $xml = $xml_header . '<updated>2009-05-01T09:32:55-07:00</updated>' . $xml_footer;
my $feed = XML::Atom::Feed->new(\$xml);
my $rl = modules::local::novemberlog->get_self();
ok(!exists($$rl{lastrev}), "no lastrev by default");
call_func('process_branch', 'master', $feed);
my $output = [output()];
is(scalar @$output, 0, "nothing output the first time around");
is($$rl{not_first_time}, 1, "not_first_time was set");
BEGIN { $tests += 3 };

# update
reset_output();
$xml_footer = << '__XML__' . $xml_footer;
  <entry>
    <id>tag:github.com,2008:Grit::Commit/7f5af50c19baf360dacc5779b9c013fb14db34d3</id>
    <link type="text/html" rel="alternate" href="http://github.com/viklund/november-wiki/commit/7f5af50c19baf360dacc5779b9c013fb14db34d3"/>
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
call_func('process_branch', 'master', $feed);
$output = [output()];
is(scalar @$output, 6, "6 lines of output");
is($$output[0]{net} , 'freenode', "line to freenode/#november-wiki");
is($$output[0]{chan}, '#november-wiki' , "line to freenode/#november-wiki");
is($$output[1]{net} , 'freenode', "line to freenode/#perl6");
is($$output[1]{chan}, '#perl6'  , "line to freenode/#perl6");
BEGIN { $tests += 5 };

# update with multiple commits having the same timestamp
reset_output();
$xml_footer = << '__XML__' . $xml_footer;
  <entry>
    <id>tag:github.com,2008:Grit::Commit/5bd02be9924c2f6013e4601e55d103b1e1a30a14</id>
    <link type="text/html" rel="alternate" href="http://github.com/viklund/november-wiki/commit/5bd02be9924c2f6013e4601e55d103b1e1a30a14"/>
    <title>Small optimizations to signature binding; costs us a PMC creation and a method call less every invocation of something that has a signature, which gives a 7% speed-up in a calling benchmark.</title>
    <updated>2009-05-15T06:45:18-07:00</updated>
    <content type="html">&lt;pre&gt;m src/classes/Signature.pir

Small optimizations to signature binding; costs us a PMC creation and a method call less every invocation of something that has a signature, which gives a 7% speed-up in a calling benchmark.&lt;/pre&gt;</content>
    <author>
      <name>jnthn</name>
    </author>
  </entry>
  <entry>
    <id>tag:github.com,2008:Grit::Commit/b49cce1a84c1f229d1c542c2dc2556e2912aa960</id>
    <link type="text/html" rel="alternate" href="http://github.com/viklund/november-wiki/commit/b49cce1a84c1f229d1c542c2dc2556e2912aa960"/>
    <title>Add some micro-benchmakrs.</title>
    <updated>2009-05-15T06:45:18-07:00</updated>
    <content type="html">&lt;pre&gt;+ tools/benchmark.pl

Add some micro-benchmakrs.&lt;/pre&gt;</content>
    <author>
      <name>jnthn</name>
    </author>
  </entry>
__XML__
$xml = $xml_header . '<updated>2009-05-15T06:45:18-07:00</updated>' . $xml_footer;
$feed = XML::Atom::Feed->new(\$xml);
call_func('process_branch', 'master', $feed);
$output = [output()];
is(scalar @$output, 12, "12 lines of output");
is($$output[0]{net} , 'freenode', "line to freenode/#november-wiki");
is($$output[0]{chan}, '#november-wiki' , "line to freenode/#november-wiki");
is($$output[1]{net} , 'freenode', "line to freenode/#perl6");
is($$output[1]{chan}, '#perl6'  , "line to freenode/#perl6");
# The module sorts by <updated> time, but the time is the same for these two commits.
# Do it this way so we don't depend on perl's internal sort algorithm details.
my @message_list = ($$output[2]{text}, $$output[8]{text});
is(scalar grep(/Small optimizations/ , @message_list), 1, "log message");
is(scalar grep(/Add some micro-bench/, @message_list), 1, "log message");
BEGIN { $tests += 7 };
