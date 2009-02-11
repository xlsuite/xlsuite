require 'acts_as_taggable'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Taggable)
