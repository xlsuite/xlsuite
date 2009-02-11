FeedTools was designed to be a simple XML feed parser, generator, and
translator with a built-in caching system.

== Example
  require 'feed_tools'
  
  slashdot_feed = FeedTools::Feed.open('http://www.slashdot.org/index.rss')
  slashdot_feed.title
  => "Slashdot"
  slashdot_feed.description
  => "News for nerds, stuff that matters"
  slashdot_feed.link       
  => "http://slashdot.org/"
  slashdot_feed.items.first.find_node("slash:hitparade/text()").to_s
  => "43,37,28,23,11,3,1"

== Installation
You can install FeedTools as a gem:
  gem install feedtools
  
Or you can install it from the tarball or zip packages on the download page
and then extract it to your vendors directory as you would with any other
Ruby library.
 
After installation, you will either need to run in non-caching mode or set
up a caching mechanism.  The database feed cache system currently included
with FeedTools is the most common caching method.  To set up the database
feed cache, you will first need to create the appropriate database schema.
Schema files for MySQL, PostgreSQL, and SQLite have been included, but the
preferred method of creating the schema within the Rails environment is with
a migration file.  A migration file has been supplied with FeedTools and can
be found in the db directory.  Run
<tt>script/generate migration add_feed_tools_tables</tt> and then copy and
paste the contents of db/migration.rb into your new migration file.