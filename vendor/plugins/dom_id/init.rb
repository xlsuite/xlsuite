require File.dirname(__FILE__) + "/lib/dom_id"
ActiveRecord::Base.send(:include, DomId)
