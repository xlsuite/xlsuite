#
# of course attributes works as well at class/module level as at instance
# level
#
  require 'attributes'

  module Logging 
    Level_names = {
      0 => 'INFO',
      # ...
      42 => 'DEBUG',
    }

    class << self
      attribute 'level' => 42
      attribute('level_name'){ Level_names[level] }
    end
  end

p Logging.level
p Logging.level_name
