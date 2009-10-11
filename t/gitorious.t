#!perl
use strict;
use warnings;

use Test::More;
use Cwd;
use lib getcwd();
use t::util;

# This configures the parrot-plumage feed; we use this feed as an entry point
# to the gitorious parser.
load_plugin("karmalog");
load_plugin("gitoriousparser");
my $url = 'http://gitorious.org/parrot-plumage/parrot-plumage';
modules::local::gitoriousparser->try_link($url);

my $tests;
BEGIN { $tests = 0; };

plan tests => $tests;

my $xml_header = << '__XML__';
<?xml version="1.0" encoding="UTF-8"?>
<feed xml:lang="en-US" xmlns="http://www.w3.org/2005/Atom">
  <id>tag:gitorious.org,2005:/parrot-plumage</id>
  <link rel="alternate" type="text/html" href="http://gitorious.org"/>
  <link rel="self" type="application/atom+xml" href="http://gitorious.org/parrot-plumage.atom"/>
  <title>Gitorious: parrot-plumage activity</title>
__XML__

my $xml_footer = << '__XML__';
  <entry>
    <id>tag:gitorious.org,2005:Event/4563325</id>
    <published>2009-09-30T00:16:24Z</published>
    <updated>2009-09-30T00:16:24Z</updated>
    <link rel="alternate" type="text/html" href="http://gitorious.org/parrot-plumage"/>
    <title>japhb pushed 1 commit  to parrot-plumage/parrot-plumage:master</title>
    <content type="html">  &lt;p&gt;&lt;a href="/~japhb"&gt;japhb&lt;/a&gt; &lt;strong&gt;pushed &lt;a href="/parrot-plumage/parrot-plumage/commits/master" class="commit_event_toggler" gts:id="4563325" gts:url="/events/4563325/commits" id="commits_in_event_4563325_toggler"&gt;1 commit&lt;/a&gt;&lt;/strong&gt;  to &lt;a href="/parrot-plumage/parrot-plumage/commits/master"&gt;parrot-plumage/parrot-plumage:master&lt;/a&gt;&lt;/p&gt;
  &lt;p&gt;master changed from af8844b to 51301cd&lt;p&gt;
&lt;ul&gt;&lt;li&gt; &lt;a href="/parrot-plumage/parrot-plumage/commit/51301cd0ee46d5a9952093a58e4f06ff8fdce09f"&gt;51301cd&lt;/a&gt;: [plumage] Add new configure type 'parrot_configure'&lt;/li&gt;&lt;/ul&gt;</content>
    <author>
      <name>japhb</name>
    </author>
  </entry>
</feed>
__XML__

# initial sync
my $xml = $xml_header . '<updated>2009-09-30T00:16:24Z</updated>' . $xml_footer;
my $feed = XML::Atom::Feed->new(\$xml);
my $rl = modules::local::parrot_plumagelog->get_self();
ok(!exists($$rl{lastrev}), "no lastrev by default");
modules::local::parrot_plumagelog->process_feed($feed);
my $output = [output()];
is(scalar @$output, 0, "nothing output the first time around");
BEGIN { $tests += 2 };

# update
$xml_footer = << '__XML__' . $xml_footer;
  <entry>
    <id>tag:gitorious.org,2005:Event/4563340</id>
    <published>2009-09-30T00:36:34Z</published>
    <updated>2009-09-30T00:36:34Z</updated>
    <link rel="alternate" type="text/html" href="http://gitorious.org/parrot-plumage"/>
    <title>darbelo pushed 1 commit  to parrot-plumage/parrot-plumage:master</title>
    <content type="html">  &lt;p&gt;&lt;a href="/~darbelo"&gt;darbelo&lt;/a&gt; &lt;strong&gt;pushed &lt;a href="/parrot-plumage/parrot-plumage/commits/master" class="commit_event_toggler" gts:id="4563340" gts:url="/events/4563340/commits" id="commits_in_event_4563340_toggler"&gt;1 commit&lt;/a&gt;&lt;/strong&gt;  to &lt;a href="/parrot-plumage/parrot-plumage/commits/master"&gt;parrot-plumage/parrot-plumage:master&lt;/a&gt;&lt;/p&gt;
  &lt;p&gt;master changed from 51301cd to 7c709f9&lt;p&gt;
&lt;ul&gt;&lt;li&gt;Daniel Arbelo Arrocha &lt;a href="/parrot-plumage/parrot-plumage/commit/7c709f9cd79ce65d35632d68ce3fe25c24a7041a"&gt;7c709f9&lt;/a&gt;: Add a metadata file for decnum-dynpmcs.&lt;/li&gt;&lt;/ul&gt;</content>
    <author>
      <name>darbelo</name>
    </author>
  </entry>
__XML__
$xml = $xml_header . '<updated>2009-09-30T00:36:34Z</updated>' . $xml_footer;
$feed = XML::Atom::Feed->new(\$xml);
modules::local::parrot_plumagelog->process_feed($feed);
$output = [output()];
is(scalar @$output, 3, "3 lines of output");
is($$output[0]{net} , 'magnet'  , "line to magnet/#parrot");
is($$output[0]{chan}, '#parrot' , "line to magnet/#parrot");
is($$output[0]{text}, 'parrot-plumage: 7c709f9 | darbelo++ | :' , "karma line");
is($$output[1]{text}, 'parrot-plumage: Add a metadata file for decnum-dynpmcs.' , "log line");
is($$output[2]{text}, 'parrot-plumage: review: http://gitorious.org/parrot-plumage/parrot-plumage/commit/7c709f9cd79ce65d35632d68ce3fe25c24a7041a' , "link line");
BEGIN { $tests += 6 };

reset_output();
# update
$xml_footer = << '__XML__' . $xml_footer;
  <entry>
    <id>tag:gitorious.org,2005:Event/4563909</id>
    <published>2009-09-30T01:07:19Z</published>
    <updated>2009-09-30T01:07:19Z</updated>
    <link rel="alternate" type="text/html" href="http://gitorious.org/parrot-plumage"/>
    <title>japhb pushed 2 commits  to parrot-plumage/parrot-plumage:master</title>
    <content type="html">  &lt;p&gt;&lt;a href="/~japhb"&gt;japhb&lt;/a&gt; &lt;strong&gt;pushed &lt;a href="/parrot-plumage/parrot-plumage/commits/master" class="commit_event_toggler" gts:id="4563909" gts:url="/events/4563909/commits" id="commits_in_event_4563909_toggler"&gt;2 commits&lt;/a&gt;&lt;/strong&gt;  to &lt;a href="/parrot-plumage/parrot-plumage/commits/master"&gt;parrot-plumage/parrot-plumage:master&lt;/a&gt;&lt;/p&gt;
  &lt;p&gt;master changed from 7c709f9 to d3858b4&lt;p&gt;
&lt;ul&gt;&lt;li&gt; &lt;a href="/parrot-plumage/parrot-plumage/commit/d3858b452a9080ca989a48422b27dcc5bbe754fc"&gt;d3858b4&lt;/a&gt;: [plumage] Use new do_run() and as_array() primitives from Glue.pir&lt;/li&gt;&lt;li&gt; &lt;a href="/parrot-plumage/parrot-plumage/commit/6d885b2fd62ae2cea578b14e45c4f09db2218d0f"&gt;6d885b2&lt;/a&gt;: [CORE] Glue.pir: Add do_run() and as_array() functions&lt;/li&gt;&lt;/ul&gt;</content>
    <author>
      <name>japhb</name>
    </author>
  </entry>
__XML__
$xml = $xml_header . '<updated>2009-09-30T01:07:19Z</updated>' . $xml_footer;
$feed = XML::Atom::Feed->new(\$xml);
modules::local::parrot_plumagelog->process_feed($feed);
$output = [output()];
is(scalar @$output, 6, "6 lines of output");
is($$output[0]{net} , 'magnet'  , "line to magnet/#parrot");
is($$output[0]{chan}, '#parrot' , "line to magnet/#parrot");
is($$output[0]{text}, 'parrot-plumage: 6d885b2 | japhb++ | :' , "karma line");
is($$output[1]{text}, 'parrot-plumage: [CORE] Glue.pir: Add do_run() and as_array() functions' , "log line");
is($$output[2]{text}, 'parrot-plumage: review: http://gitorious.org/parrot-plumage/parrot-plumage/commit/6d885b2fd62ae2cea578b14e45c4f09db2218d0f' , "link line");
is($$output[3]{text}, 'parrot-plumage: d3858b4 | japhb++ | :' , "karma line");
is($$output[4]{text}, 'parrot-plumage: [plumage] Use new do_run() and as_array() primitives from Glue.pir' , "log line");
is($$output[5]{text}, 'parrot-plumage: review: http://gitorious.org/parrot-plumage/parrot-plumage/commit/d3858b452a9080ca989a48422b27dcc5bbe754fc' , "link line");
BEGIN { $tests += 9 };


