#
# my favourite element of attributes is that getters can also be setters.
# this allows incredibly clean looking code like
#
  require 'attributes'

  class Config
    attributes %w( host port)
    def initialize(&block) instance_eval &block end
  end

  conf = Config.new{
    host 'codeforpeople.org'

    port 80
  }

  p conf
