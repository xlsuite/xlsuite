#--
# Color
# Colour management with Ruby
# http://rubyforge.org/projects/color
#   Version 1.4.0
#
# Licensed under a MIT-style licence. See Licence.txt in the main
# distribution for full licensing information.
#
# Copyright (c) 2005 - 2007 Austin Ziegler and Matt Lyon
#
# $Id: test_all.rb 55 2007-02-03 23:29:34Z austin $
#++

require 'color'

# This namespace contains some CSS colour names.
module Color::CSS
  # Returns the RGB colour for name or +nil+ if the name is not valid.
  def self.[](name)
    @colors[name.to_s.downcase.to_sym]
  end

  @colors = {}
  Color::RGB.constants.each do |const|
    next if const == "PDF_FORMAT_STR"
    next if const == "Metallic"
    @colors[const.downcase.to_sym] ||= Color::RGB.const_get(const)
  end
end
