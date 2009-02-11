#!/usr/bin/env ruby
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

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0
require 'test/unit'
require 'color'
require 'color/css'

module TestColor
  class TestCSS < Test::Unit::TestCase
    def test_index
      assert_equal(Color::RGB::AliceBlue, Color::CSS[:aliceblue])
      assert_equal(Color::RGB::AliceBlue, Color::CSS["AliceBlue"])
      assert_equal(Color::RGB::AliceBlue, Color::CSS["aliceBlue"])
      assert_equal(Color::RGB::AliceBlue, Color::CSS["aliceblue"])
      assert_equal(Color::RGB::AliceBlue, Color::CSS[:AliceBlue])
    end
  end
end
