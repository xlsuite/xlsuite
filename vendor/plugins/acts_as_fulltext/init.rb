require "acts_as_fulltext"
ActiveRecord::Base.send :include, ActsAsFulltext
