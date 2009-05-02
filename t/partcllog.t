#!perl
use strict;
use warnings;

use Test::More;
use Cwd;
use lib getcwd();
use t::util;

# this configures the partcl feed, among others.
load_plugin("karmalog");
load_plugin("autofeed");

my $tests;
BEGIN { $tests = 0; };

plan tests => $tests;

my $xml_header = << '__XML__';
<?xml version="1.0"?>

<feed xmlns="http://www.w3.org/2005/Atom">
 <id>http://code.google.com/feeds/p/partcl/svnchanges/basic</id>
 <title>Subversion commits to project partcl on Google Code</title>
 <link rel="alternate" type="text/html" href="http://code.google.com/p/partcl/source/list"/>
 <link rel="self" type="application/atom+xml;type=feed" href="http://code.google.com/feeds/p/partcl/svnchanges/basic"/>
__XML__

my $xml_footer = << '__XML__';
  <entry>
 <updated>2009-01-27T04:26:23Z</updated>
 <id>http://code.google.com/feeds/p/partcl/svnchanges/basic/321</id>
 <link rel="alternate" type="text/html"
 href="http://code.google.com/p/partcl/source/detail?r=321" />
 <title>Revision 321: Fixup recent FV fixes. All tests in &#39;make test&#39; pass again. &#39;mathop.test&#39; back u</title>
 <author>
 <name>wcoleda</name>
 </author>
 <content type="html">
 Changed Paths:&lt;br/&gt;
 &#160;&#160;&#160;&#160;Modify&#160;&#160;&#160;&#160;/trunk/src/pmc/tclobject.pmc
 
 &lt;br/&gt;
 &lt;br/&gt;Fixup recent FV fixes. All tests in &#39;make test&#39; pass again. &#39;mathop.test&#39; back
up to cover the lost 8 tests.

 </content>
</entry>

</feed>
__XML__

# initial sync
my $xml = $xml_header . '<updated>2009-01-27T04:26:23Z</updated>' . $xml_footer;
my $feed = XML::Atom::Feed->new(\$xml);
my $rl = modules::local::partcllog->get_self();
ok(!exists($$rl{lastrev}), "no lastrev by default");
modules::local::partcllog->process_feed($feed);
my $output = [output()];
is(scalar @$output, 0, "nothing output the first time around");
is($$rl{lastrev}, "2009-01-27T04:26:23Z", "lastrev was set");
BEGIN { $tests += 3 };

# update
$xml_footer = << '__XML__' . $xml_footer;
  <entry>
 <updated>2009-01-27T15:44:28Z</updated>
 <id>http://code.google.com/feeds/p/partcl/svnchanges/basic/322</id>
 <link rel="alternate" type="text/html"
 href="http://code.google.com/p/partcl/source/detail?r=322" />
 <title>Revision 322: [array unset a] should unset the entire array, not all the array&#39;s contents. </title>
 <author>
 <name>wcoleda</name>
 </author>
 <content type="html">
 Changed Paths:&lt;br/&gt;
 &#160;&#160;&#160;&#160;Modify&#160;&#160;&#160;&#160;/trunk/runtime/builtin/array.pir
 
 &lt;br/&gt;
 &lt;br/&gt;[array unset a] should unset the entire array, not all the array&#39;s contents.

 </content>
</entry>
__XML__
$xml = $xml_header . '<updated>2009-01-27T15:44:28Z</updated>' . $xml_footer;
$feed = XML::Atom::Feed->new(\$xml);
modules::local::partcllog->process_feed($feed);
$output = [output()];
is(scalar @$output, 3, "3 lines of output");
is($$output[0]{net} , 'magnet'  , "line to magnet/#parrot");
is($$output[0]{chan}, '#parrot' , "line to magnet/#parrot");
is($$output[0]{text}, 'partcl: r322 | coke++ | trunk/runtime/builtin/array.pir:' , "karma line");
is($$output[1]{text}, 'partcl: [array unset a] should unset the entire array, not all the array\'s contents.' , "log line");
is($$output[2]{text}, 'partcl: review: http://code.google.com/p/partcl/source/detail?r=322' , "link line");
is($$rl{lastrev}, "2009-01-27T15:44:28Z", "lastrev was updated");
BEGIN { $tests += 7 };
