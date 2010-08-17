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

my $yaml_header = << '__YAML__';
--- 
commits: 
__YAML__

my $yaml_footer = << '__YAML__';
- parents: 
  - id: da4527eb728cf268cfcdbb772b2c781458c49994
  author: 
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
  url: http://github.com/viklund/november/commit/78805c2e9337d2d72a28b11e632b37cd31feeb8c
  id: 78805c2e9337d2d72a28b11e632b37cd31feeb8c
  committed_date: "2009-11-01T12:57:46-08:00"
  authored_date: "2009-11-01T12:57:46-08:00"
  message: "[08-formatting-and-links.t] fixed bitrot"
  tree: 93b789bdadc6dc60119959806422481e8701b4fb
  committer: 
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
__YAML__

# initial sync
my $yaml = $yaml_header . $yaml_footer;
my $feed = YAML::Syck::Load($yaml);
my $rl = modules::local::novemberlog->get_self();
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
  - id: 6d57c895b86859b5c2c7305d21d3b6ad0dd6bde2
  author:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
  url: http://github.com/viklund/november/commit/4e56a149a03c010a31d279d4bba93bf
  id: 4e56a149a03c010a31d279d4bba93bf3b9ca74fe
  committed_date: "2010-05-05T07:10:11-07:00"
  authored_date: "2010-05-05T07:10:11-07:00"
  message: "[docs/blog-posts.md] fixed copy-paste-o"
  tree: 314e6df17f751c1811b2548a383a7cef5c596b93
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
is($$output[0]{net} , 'freenode', "line to freenode/#november-wiki");
is($$output[0]{chan}, '#november-wiki' , "line to freenode/#november-wiki");
is($$output[1]{net} , 'freenode', "line to freenode/#perl6");
is($$output[1]{chan}, '#perl6'  , "line to freenode/#perl6");
BEGIN { $tests += 5 };

# update with multiple commits having the same timestamp
reset_output();
$yaml_footer = << '__YAML__' . $yaml_footer;
- parents:
  - id: c5fd6a474718a4e7a986db3216c7ea63ecd12387
  author:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
  url: http://github.com/viklund/november/commit/6d57c895b86859b5c2c7305d21d3b6a
  id: 6d57c895b86859b5c2c7305d21d3b6ad0dd6bde2
  committed_date: "2010-05-05T07:05:17-07:00"
  authored_date: "2010-05-05T07:05:17-07:00"
  message: |-
    [docs/blog-posts.md] links to all known posts

    ...about November. Tried to find them all in my feed; might have missed seme
    Definitely missed some from other people. Feel free to supplement.
  tree: ecaf0815787f742fa9976883c7a40d4b7f744a73
  committer:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
- parents:
  - id: 95134d49a4d5e168ad17244bbcfd9927cf684cf4
  author:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
  url: http://github.com/viklund/november/commit/c5fd6a474718a4e7a986db3216c7ea6
  id: c5fd6a474718a4e7a986db3216c7ea63ecd12387
  committed_date: "2010-05-05T07:05:17-07:00"
  authored_date: "2010-05-05T07:05:17-07:00"
  message: |-
    [Makefile] added to version control

    It assumes an installed 'perl6', as opposed to the old one.
  tree: aa0438d1b6ede0bcea2cfeb4880e5ddd512697bf
  committer:
    name: Carl Masak
    login: masak
    email: cmasak@gmail.com
__YAML__
$yaml = $yaml_header . $yaml_footer;
$feed = YAML::Syck::Load($yaml);
call_func('process_branch', 'master', $feed);
$output = [output()];
is(scalar @$output, 22, "22 lines of output");
is($$output[0]{net} , 'freenode', "line to freenode/#november-wiki");
is($$output[0]{chan}, '#november-wiki' , "line to freenode/#november-wiki");
is($$output[1]{net} , 'freenode', "line to freenode/#perl6");
is($$output[1]{chan}, '#perl6'  , "line to freenode/#perl6");
# The module sorts by <updated> time, but the time is the same for these two commits.
# Do it this way so we don't depend on perl's internal sort algorithm details.
my @message_list = ($$output[6]{text}, $$output[14]{text});
is(scalar grep(/Tried to find them/ , @message_list), 1, "log message");
is(scalar grep(/added to version/, @message_list), 1, "log message");
BEGIN { $tests += 7 };
