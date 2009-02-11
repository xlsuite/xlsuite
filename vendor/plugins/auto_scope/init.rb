require "xl_suite/auto_scope"
ActiveRecord::Base.send(:extend, XlSuite::AutoScope)
