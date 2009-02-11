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
  class TestGrayScale < Test::Unit::TestCase
    def setup
      @gs = Color::GrayScale.from_percent(33)
    end

    def test_brightness
      assert_in_delta(0.33, @gs.brightness, Color::COLOR_TOLERANCE)
    end

    def test_darken_by
      assert_in_delta(29.7, @gs.darken_by(10).gray, Color::COLOR_TOLERANCE)
    end

    def test_g
      assert_in_delta(0.33, @gs.g, Color::COLOR_TOLERANCE)
      assert_in_delta(33, @gs.grey, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @gs.gray = 40 }
      assert_in_delta(0.4, @gs.g, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @gs.g = 2.0 }
      assert_in_delta(100, @gs.gray, Color::COLOR_TOLERANCE)
      assert_nothing_raised { @gs.grey = -2.0 }
      assert_in_delta(0.0, @gs.g, Color::COLOR_TOLERANCE)
    end

    def test_html_css
      assert_equal("#545454", @gs.html)
      assert_equal("rgb(33.00%, 33.00%, 33.00%)", @gs.css_rgb)
      assert_equal("rgba(33.00%, 33.00%, 33.00%, 1.00)", @gs.css_rgba)
    end

    def test_lighten_by
      assert_in_delta(0.363, @gs.lighten_by(10).g, Color::COLOR_TOLERANCE)
    end

    def test_pdf_fill
      assert_equal("0.330 g", @gs.pdf_fill)
      assert_equal("0.330 G", @gs.pdf_stroke)
    end

    def test_to_cmyk
      cmyk = nil
      assert_nothing_raised { cmyk = @gs.to_cmyk }
      assert_kind_of(Color::CMYK, cmyk)
      assert_in_delta(0.0, cmyk.c, Color::COLOR_TOLERANCE)
      assert_in_delta(0.0, cmyk.m, Color::COLOR_TOLERANCE)
      assert_in_delta(0.0, cmyk.y, Color::COLOR_TOLERANCE)
      assert_in_delta(0.67, cmyk.k, Color::COLOR_TOLERANCE)
    end

    def test_to_grayscale
      assert_equal(@gs, @gs.to_grayscale)
      assert_equal(@gs, @gs.to_greyscale)
    end

    def test_to_hsl
      hsl = nil
      assert_nothing_raised { hsl = @gs.to_hsl }
      assert_kind_of(Color::HSL, hsl)
      assert_in_delta(0.0, hsl.h, Color::COLOR_TOLERANCE)
      assert_in_delta(0.0, hsl.s, Color::COLOR_TOLERANCE)
      assert_in_delta(0.33, hsl.l, Color::COLOR_TOLERANCE)
      assert_equal("hsl(0.00, 0.00%, 33.00%)", @gs.css_hsl)
      assert_equal("hsla(0.00, 0.00%, 33.00%, 1.00)", @gs.css_hsla)
    end

    def test_to_rgb
      rgb = nil
      assert_nothing_raised { rgb = @gs.to_rgb }
      assert_kind_of(Color::RGB, rgb)
      assert_in_delta(0.33, rgb.r, Color::COLOR_TOLERANCE)
      assert_in_delta(0.33, rgb.g, Color::COLOR_TOLERANCE)
      assert_in_delta(0.33, rgb.b, Color::COLOR_TOLERANCE)
    end

    def test_to_yiq
      yiq = nil
      assert_nothing_raised { yiq = @gs.to_yiq }
      assert_kind_of(Color::YIQ, yiq)
      assert_in_delta(0.33, yiq.y, Color::COLOR_TOLERANCE)
      assert_in_delta(0.0, yiq.i, Color::COLOR_TOLERANCE)
      assert_in_delta(0.0, yiq.q, Color::COLOR_TOLERANCE)
    end

    def test_add
      delta = @gs + Color::GrayScale.new(20)
      max   = @gs + Color::GrayScale.new(80)

      assert_in_delta(1.0, max.g, Color::COLOR_TOLERANCE)
      assert_in_delta(0.53, delta.g, Color::COLOR_TOLERANCE)
    end

    def test_subtract
      delta = @gs - Color::GrayScale.new(20)
      max   = @gs - Color::GrayScale.new(80)
      assert_in_delta(0.0, max.g, Color::COLOR_TOLERANCE)
      assert_in_delta(0.13, delta.g, Color::COLOR_TOLERANCE)
    end

    def test_inspect
      assert_equal("Gray [33.00%]", @gs.inspect)
    end
  end
end
