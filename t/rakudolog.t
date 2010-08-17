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

my $yaml_header = << '__YAML__';
---
commits:
__YAML__

my $yaml_footer = << '__YAML__';
- parents:
  - id: 83b2cdfa64becdef052417962cc114e38f5920d8
  author:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
  url: http://github.com/rakudo/rakudo/commit/73a76745a0de01b7361a75ac8347c516532f92aa
  id: 73a76745a0de01b7361a75ac8347c516532f92aa
  committed_date: "2010-08-15T16:59:44-07:00"
  authored_date: "2010-08-15T16:59:44-07:00"
  message: "[Buf] added prefix/infix ~^, infix ~& and infix ~|"
  tree: c797ca702afa584fa8a28d44376b3e942174c30e
  committer:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
__YAML__

# initial sync
my $yaml = $yaml_header . $yaml_footer;
my $feed = YAML::Syck::Load($yaml);
my $rl = modules::local::rakudolog->get_self();
ok(!exists($$rl{lastrev}), "no lastrev by default");
call_func('process_branch', 'master', $feed);
my $output = [output()];
is(scalar @$output, 0, "nothing output the first time around");
is($$rl{not_first_time}, undef, "not_first_time was undef by default");
BEGIN { $tests += 3 };

# update
reset_output();
$$rl{not_first_time} = 1;
$yaml_footer = << '__YAML__' . $yaml_footer;
- parents:
  - id: 73a76745a0de01b7361a75ac8347c516532f92aa
  author:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
  url: http://github.com/rakudo/rakudo/commit/bef86ee3a3253a8840c077e5d1a089579949a58a
  id: bef86ee3a3253a8840c077e5d1a089579949a58a
  committed_date: "2010-08-15T17:04:08-07:00"
  authored_date: "2010-08-15T17:04:08-07:00"
  message: "[t/spectest.data] added S03-operators/buf.t"
  tree: c809290826b06fa32adae1a76d1d987ed632b5cc
  committer:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
__YAML__
$yaml = $yaml_header . $yaml_footer;
$feed = YAML::Syck::Load($yaml);
call_func('process_branch', 'master', $feed);
$output = [output()];
is(scalar @$output, 6, "6 lines of output");
is($$output[0]{net} , 'magnet'  , "line to magnet/#parrot");
is($$output[0]{chan}, '#parrot' , "line to magnet/#parrot");
like($$output[0]{text}, qr|rakudo: |, "master branch");
is($$output[1]{net} , 'freenode', "line to freenode/#perl6");
is($$output[1]{chan}, '#perl6'  , "line to freenode/#perl6");
like($$output[1]{text}, qr|rakudo: |, "master branch");
BEGIN { $tests += 7 };
