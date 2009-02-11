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

module TestColor
  class TestCMYK < Test::Unit::TestCase
    def setup
      @cmyk = Color::CMYK.new(10, 20, 30, 40)
    end

    def test_cyan
      assert_in_delta(0.1, @cmyk.c, Color::COLOR_TOLERANCE)
      assert_in_delta(10, @cmyk.cyan, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.cyan = 20 }
      assert_in_delta(0.2, @cmyk.c, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.c = 2.0 }
      assert_in_delta(100, @cmyk.cyan, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.c = -1.0 }
      assert_in_delta(0.0, @cmyk.c, Color::COLOR_TOLERANCE)
    end

    def test_magenta
      assert_in_delta(0.2, @cmyk.m, Color::COLOR_TOLERANCE)
      assert_in_delta(20, @cmyk.magenta, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.magenta = 30 }
      assert_in_delta(0.3, @cmyk.m, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.m = 2.0 }
      assert_in_delta(100, @cmyk.magenta, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.m = -1.0 }
      assert_in_delta(0.0, @cmyk.m, Color::COLOR_TOLERANCE)
    end

    def test_yellow
      assert_in_delta(0.3, @cmyk.y, Color::COLOR_TOLERANCE)
      assert_in_delta(30, @cmyk.yellow, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.yellow = 20 }
      assert_in_delta(0.2, @cmyk.y, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.y = 2.0 }
      assert_in_delta(100, @cmyk.yellow, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.y = -1.0 }
      assert_in_delta(0.0, @cmyk.y, Color::COLOR_TOLERANCE)
    end

    def test_black
      assert_in_delta(0.4, @cmyk.k, Color::COLOR_TOLERANCE)
      assert_in_delta(40, @cmyk.black, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.black = 20 }
      assert_in_delta(0.2, @cmyk.k, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.k = 2.0 }
      assert_in_delta(100, @cmyk.black, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @cmyk.k = -1.0 }
      assert_in_delta(0.0, @cmyk.k, Color::COLOR_TOLERANCE)
    end

    def test_pdf
      assert_equal("0.100 0.200 0.300 0.400 k", @cmyk.pdf_fill)
      assert_equal("0.100 0.200 0.300 0.400 K", @cmyk.pdf_stroke)
    end

    def test_to_cmyk
      assert(@cmyk.to_cmyk == @cmyk)
    end

    def test_to_grayscale
      gs = nil
      assert_nothing_raised { gs = @cmyk.to_grayscale }
      assert_kind_of(Color::GrayScale, gs)
      assert_in_delta(0.4185, gs.g, Color::COLOR_TOLERANCE)
      assert_kind_of(Color::GreyScale, @cmyk.to_greyscale)
    end

    def test_to_hsl
      hsl = nil
      assert_nothing_raised { hsl = @cmyk.to_hsl }
      assert_kind_of(Color::HSL, hsl)
      assert_in_delta(0.48, hsl.l, Color::COLOR_TOLERANCE)
      assert_in_delta(0.125, hsl.s, Color::COLOR_TOLERANCE)
      assert_in_delta(0.08333, hsl.h, Color::COLOR_TOLERANCE)
      assert_equal("hsl(30.00, 12.50%, 48.00%)", @cmyk.css_hsl)
      assert_equal("hsla(30.00, 12.50%, 48.00%, 1.00)", @cmyk.css_hsla)
    end

    def test_to_rgb
      rgb = nil
      assert_nothing_raised { rgb = @cmyk.to_rgb(true) }
      assert_kind_of(Color::RGB, rgb)
      assert_in_delta(0.5, rgb.r, Color::COLOR_TOLERANCE)
      assert_in_delta(0.4, rgb.g, Color::COLOR_TOLERANCE)
      assert_in_delta(0.3, rgb.b, Color::COLOR_TOLERANCE)

      assert_nothing_raised { rgb = @cmyk.to_rgb }
      assert_kind_of(Color::RGB, rgb)
      assert_in_delta(0.54, rgb.r, Color::COLOR_TOLERANCE)
      assert_in_delta(0.48, rgb.g, Color::COLOR_TOLERANCE)
      assert_in_delta(0.42, rgb.b, Color::COLOR_TOLERANCE)

      assert_equal("#8a7a6b", @cmyk.html)
      assert_equal("rgb(54.00%, 48.00%, 42.00%)", @cmyk.css_rgb)
      assert_equal("rgba(54.00%, 48.00%, 42.00%, 1.00)", @cmyk.css_rgba)
    end

    def test_inspect
      assert_equal("CMYK [10.00%, 20.00%, 30.00%, 40.00%]", @cmyk.inspect)
    end

    def test_to_yiq
      yiq = nil
      assert_nothing_raised { yiq = @cmyk.to_yiq }
      assert_kind_of(Color::YIQ, yiq)
      assert_in_delta(0.4911, yiq.y, Color::COLOR_TOLERANCE)
      assert_in_delta(0.05502, yiq.i, Color::COLOR_TOLERANCE)
      assert_in_delta(0.0, yiq.q, Color::COLOR_TOLERANCE)
    end
  end
end
