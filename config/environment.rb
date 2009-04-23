# Be sure to restart your webserver when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
# RAILS_ENV  = ENV['RAILS_ENV'] || 'production'

RAILS_CONNECTION_ADAPTERS = %w(mysql)

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Add additional load paths for your own custom dirs
  config.load_paths += Dir[File.join(RAILS_ROOT, 'vendor', 'gems', '*[0-9]', 'lib')]
  config.load_paths << File.join(RAILS_ROOT, "app", "actions")
  config.load_paths << File.join(RAILS_ROOT, "app", "apis")
  config.load_paths << File.join(RAILS_ROOT, "app", "behaviors")
  config.load_paths << File.join(RAILS_ROOT, "app", "concerns")
  config.load_paths << File.join(RAILS_ROOT, "app", "drops")
  config.load_paths << File.join(RAILS_ROOT, "app", "futures")
  config.load_paths << File.join(RAILS_ROOT, "app", "liquid_filters")
  config.load_paths << File.join(RAILS_ROOT, "app", "liquid_tags")

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Activate observers that should always be running
  config.active_record.observers = :point_blog_observer, :point_blog_post_observer, 
    :point_comment_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  config.active_record.schema_format = :sql
  config.active_record.colorize_logging = false

  # See Rails::Configuration for more options

  # This has been done in the production branch - don't freak out, François.
  config.action_controller.session = { :session_key => "session_id", :secret => "some secret phrase of at least 30 characters" }

  config.gem "actionwebservice",    :version => "= 1.2.6", :lib => "action_web_service"
  config.gem "hpricot"
  config.gem "builder",             :version => "~> 2.1"
  config.gem "money",               :version => "~> 1.7"
  config.gem "builder",             :version => "~> 2.1"
  config.gem "chronic",             :version => "~> 0.2"
  config.gem "fastercsv",           :version => "~> 1.4"
  config.gem "graticule",           :version => "~> 0.2"
  config.gem "main",                :version => "~> 2.8"
  config.gem "paypal",              :version => "~> 2.0"
  config.gem "paginator",           :version => "~> 1.0"
  config.gem "scrapi",              :version => "~> 1.2"
  config.gem "uuidtools",           :version => "~> 1.0"
  config.gem "mechanize",           :version => "~> 0.8"
  # config.gem "XMLCanonicalizer",    :version => "~> 1.0", :lib => "xmlcanonicalizer"
  config.gem "archive-tar-minitar", :version => "~> 0.5", :lib => "archive/tar/minitar"
  config.gem "pdf-writer",          :version => "~> 1.1", :lib => "pdf/writer"
  config.gem "RedCloth",            :version => "~> 4.0", :lib => "redcloth"
  config.gem "mime-types",          :version => "~> 1.15", :lib => "mime/types"

  # We do depend on the mysql gem, but it is loaded through another mechanism
  # config.gem "mysql",               :version => "~> 2.7"
end

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

require "net/imap"

require "smalltalk"
require 'extended_nil'
require 'array_extensions'
require 'feed_tools'
require "uuid_generator"
require "core_ext/hash"
require "core_ext/string"
require "core_ext/object"
require "core_ext/time"
require "s3_backend_ext"
require "geolocatable"

require "active_merchant_ext/exact"

require "domain_matcher"

require 'pp'

require "active_record_warnings"
require "actionpack_ext"

require "tmail_mail_extension"
require "multiple_smtp_action_mailer"

Money.default_currency = 'CAD'
InchesPerFeet = 12.0
ItemsPerPage = 10 # 30 items per page, when navigation is required
                  # Internal use only
DATETIME_STRFTIME_FORMAT = "%b %d, %Y %I:%M %p"
DATE_STRFTIME_FORMAT = "%b %d, %Y"

FeedTools.configurations[:feed_cache] = FeedTools::DatabaseFeedCache

FULL_DAY_NAMES = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
FULL_MONTH_NAMES = %w(January February March April May June July August September October November December)

String.send :include, XlSuite::SlugHelper

FightTheMelons::Helpers::FormMultipleSelectHelperConfiguration.outer_class = 'multiple_select'
FightTheMelons::Helpers::FormMultipleSelectHelperConfiguration.alternate = true

WhiteListHelper.tags.merge %w(meta dl dd dt input form select option label table caption thead tbody tfoot tr th td)
WhiteListHelper.attributes.merge %w(id style action type name value)


REJECTED_RETURN_TO_PATH = /(^\/admin$|^\/admin\/ui|^\/javascripts|\.xml\?|\.json\?|^\/sessions|^\/stylesheets\/)/i.freeze
EXPIRED_ACCOUNT_DEADLINE_IN_MONTH = 3

# Load report model objects so that they exist in memory and YAML::load can
# instantiate the correct classes, or else the objects are left as YAML::Object.
Dir[File.join(RAILS_ROOT, "app", "models", "report*.rb")].each do |filename|
  File.basename(filename, ".rb").classify.constantize
end

# Load action objects so that they exist in memory and YAML::load can
# instantiate the correct classes, or else the objects are left as YAML::Object.
Dir[File.join(RAILS_ROOT, "app", "actions", "*.rb")].each do |filename|
  File.basename(filename, ".rb").classify.constantize
end

if RAILS_ENV=="development"
  # these hacks kind of change everything around
  require 'dispatcher_hacks'
  require 'dep_hacks'
#  ActionView.eager_load_templates=false
  
  # for rails 2.1
  # require 'template_finder_hacks'
  # for rails 2.2
  require 'template_renderable_hacks'
end
