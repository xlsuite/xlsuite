# Conditional loads, since we may have these libraries elsewhere,
# e.g. when using Rails with assert_select plugin.
require File.join(File.dirname(__FILE__), "html", "document") unless defined?(HTML::Document)
require File.join(File.dirname(__FILE__), "html", "node_ext") unless defined?(HTML::Node.detach)
require File.join(File.dirname(__FILE__), "html", "selector") unless defined?(HTML::Selector)
require File.join(File.dirname(__FILE__), "html", "htmlparser") unless defined?(HTML::HTMLParser)

require File.join(File.dirname(__FILE__), "scraper", "base") unless defined?(Scraper::Base)
