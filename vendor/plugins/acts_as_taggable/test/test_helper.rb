ENV["RAILS_ENV"] = "test"
require 'pathname'; here = Pathname.new(__FILE__).dirname
require here.join("../../../../config/environment")
require 'test_help'

config = YAML::load(ERB.new(here.join('database.yml').read).result)

ActiveRecord::Base.logger = Logger.new(here.join('debug.log').to_s)
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])

load here.join('schema.rb')

Test::Unit::TestCase.fixture_path = here.join('fixtures').to_s
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
