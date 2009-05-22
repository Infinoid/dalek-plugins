#!perl
use strict;
use warnings;
use utf8;

use Test::More;
use Cwd;
use lib getcwd();
use t::util;

load_plugin("parrotticketlog");

my $tests;
BEGIN { $tests = 0; };

plan tests => $tests;

my $xml_header = << '__XML__';
<?xml version="1.0"?>
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">


  <channel>
    <title>Parrot</title>
    <link>https://trac.parrot.org/parrot/timeline</link>
    <description>Trac Timeline</description>
    <language>en-US</language>
    <generator>Trac 0.11.2</generator>
    <image>
      <title>Parrot</title>
      <url>https://trac.parrot.org/parrot/chrome/site/parrot_logo.png</url>
      <link>https://trac.parrot.org/parrot/timeline</link>
    </image>
__XML__

my $xml_footer = << '__XML__';
    <item>
      <title>Ticket #693 (Add 'Wiki' to top row buttons at http://www.parrot.org) created</title>
          <dc:creator>jkeenan</dc:creator>
        <pubDate>Wed, 20 May 2009 23:34:29 GMT</pubDate>
        <link>https://trac.parrot.org/parrot/ticket/693</link>
      <guid isPermaLink="false">/1242862469</guid>
      <description>&lt;p&gt;
Our home page currently displays this row of select buttons at the top of the page:
&lt;/p&gt;
&lt;p&gt;
&lt;strong&gt;Download News Developer Docs Languages Foundation Sponsors&lt;/strong&gt;
&lt;/p&gt;
&lt;p&gt;
At least 50% of the time I go to the site, what I &lt;i&gt;really&lt;/i&gt; want to do is go to the wiki.  So I recommend that &lt;strong&gt;Wiki&lt;/strong&gt; be added, perhaps between Docs and Languages.
&lt;/p&gt;
&lt;p&gt;
Thank you very much.&lt;br /&gt;
kid51
&lt;/p&gt;
</description>
      <category>newticket</category>
    </item>
   </channel>
</rss>
__XML__

# initial sync
my $xml = $xml_header . $xml_footer;
my $feed = XML::RAI->parse_string($xml);
modules::local::parrotticketlog::process_feed($feed);
my $output = [output()];
is(scalar @$output, 0, "nothing output the first time around");
BEGIN { $tests += 1 };

# update
$xml_footer = << '__XML__' . $xml_footer;
    <item>
      <title>Ticket #695 (subtest 3 in t/dynoplibs/myops.t segfaults on darwin) created</title>
          <dc:creator>urkle</dc:creator>
        <pubDate>Thu, 21 May 2009 03:03:28 GMT</pubDate>
        <link>https://trac.parrot.org/parrot/ticket/695</link>
      <guid isPermaLink="false">/1242875008</guid>
      <description>&lt;p&gt;
subtest 3 in the t/dynoplibs/myops.t segfault on darwin (Mac OS X Leopard 10.5.7).
&lt;/p&gt;
&lt;p&gt;
Here is the stack trace.
&lt;/p&gt;
&lt;pre class="wiki"&gt;0   libSystem.B.dylib                   0x92dbfe42 __kill + 10
1   libSystem.B.dylib                   0x92e3223a raise + 26
2   libSystem.B.dylib                   0x92e3e679 abort + 73
3   myops_ops.bundle                    0x0073235b Parrot_hcf + 11 (myops.ops:56)
4   libparrot.dylib                     0x004745f4 runops_slow_core + 260 (cores.c:462)
5   libparrot.dylib                     0x004737f6 runops_int + 422 (main.c:986)
6   libparrot.dylib                     0x004211d0 runops + 240 (ops.c:111)
7   libparrot.dylib                     0x00421489 runops_args + 649 (ops.c:257)
8   libparrot.dylib                     0x004222da Parrot_runops_fromc_args + 186 (ops.c:325)
9   libparrot.dylib                     0x003fef3e Parrot_runcode + 750 (embed.c:1010)
10  libparrot.dylib                     0x005e6743 imcc_run_pbc + 323 (main.c:807)
11  libparrot.dylib                     0x005e73c9 imcc_run + 873 (main.c:1099)
12  parrot                              0x00001a79 main + 185 (main.c:61)
13  parrot                              0x00001986 start + 54
&lt;/pre&gt;</description>
      <category>newticket</category>
    </item><item>
      <title>Ticket #694 (docs/dev/fhs.pod… Is this file still relevant?) created</title>
          <dc:creator>jkeenan</dc:creator>
        <pubDate>Thu, 21 May 2009 00:47:45 GMT</pubDate>
        <link>https://trac.parrot.org/parrot/ticket/694</link>
      <guid isPermaLink="false">/1242866865</guid>
      <description>&lt;p&gt;
&lt;i&gt;docs/dev/fhs.pod&lt;/i&gt; appears to have undergone no significant changes since it was first contributed to the repository by Florian Ragwitz (rafl) in &lt;a class="changeset" href="https://trac.parrot.org/parrot/changeset/10357" title=" r22868@ata:  rafl | 2005-12-05 23:18:37 +0100
 * Added docs/dev/fhs.pod
"&gt;r10357&lt;/a&gt; in December 2005 (see attachment).  Its aim was to introduce readers to the Filesystem Hierarchy Standard (FHS) and to assess its impact on Parrot.
&lt;/p&gt;
&lt;p&gt;
We should assess whether this file's content is still relevant, whether its concerns have been assimilated into other documents, and so forth.
&lt;/p&gt;
&lt;p&gt;
I stumbled upon this file while looking at  &lt;a class="ext-link" href="http://rt.perl.org/rt3/Ticket/Display.html?id=56996"&gt;&lt;span class="icon"&gt;RT 56996:  remove non FHS-compliant searchpaths&lt;/span&gt;&lt;/a&gt;.  We need a better understanding of FHS before we can resolve that ticket, which is one reason why we should evaluate &lt;i&gt;fhs.pod&lt;/i&gt;.
&lt;/p&gt;
&lt;p&gt;
Comments?  Thank you very much.
&lt;/p&gt;
&lt;p&gt;
kid51
&lt;/p&gt;
</description>
      <category>newticket</category>
    </item>
__XML__
$xml = $xml_header . $xml_footer;
$feed = XML::RAI->parse_string($xml);
modules::local::parrotticketlog::process_feed($feed);
$output = [output()];
is(scalar @$output, 2, "2 lines of output");
is($$output[0]{net} , 'magnet'  , "line to magnet/#parrot");
is($$output[0]{chan}, '#parrot' , "line to magnet/#parrot");
is($$output[0]{text}, 'TT #694 created by jkeenan++: docs/dev/fhs.pod... Is this file still relevant?', 'log line');
is($$output[1]{text}, 'TT #695 created by urkle++: subtest 3 in t/dynoplibs/myops.t segfaults on darwin' , 'log line');
BEGIN { $tests += 5 };
