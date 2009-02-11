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
# HSL Tests provided by Adam Johnson
#
# $Id: test_all.rb 55 2007-02-03 23:29:34Z austin $
#++

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0
require 'test/unit'
require 'color'

module TestColor
  class TestHSL < Test::Unit::TestCase
    def setup
#     @hsl = Color::HSL.new(262, 67, 42)
      @hsl = Color::HSL.new(145, 20, 30)
#     @rgb = Color::RGB.new(88, 35, 179)
    end

    def test_rgb_roundtrip_conversion
      hsl = Color::HSL.new(262, 67, 42)
      c = hsl.to_rgb.to_hsl
      assert_in_delta hsl.h, c.h, Color::COLOR_TOLERANCE, "Hue"
      assert_in_delta hsl.s, c.s, Color::COLOR_TOLERANCE, "Saturation"
      assert_in_delta hsl.l, c.l, Color::COLOR_TOLERANCE, "Luminance"
    end

    def test_brightness
      assert_in_delta 0.3, @hsl.brightness, Color::COLOR_TOLERANCE
    end

    def test_hue
      assert_in_delta 0.4027, @hsl.h, Color::COLOR_TOLERANCE
      assert_in_delta 145, @hsl.hue, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.hue = 33 }
      assert_in_delta 0.09167, @hsl.h, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.hue = -33 }
      assert_in_delta 0.90833, @hsl.h, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.h = 3.3 }
      assert_in_delta 360, @hsl.hue, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.h = -3.3 }
      assert_in_delta 0.0, @hsl.h, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.hue = 0 }
      assert_nothing_raised { @hsl.hue -= 20 }
      assert_in_delta 340, @hsl.hue, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.hue += 45 }
      assert_in_delta 25, @hsl.hue, Color::COLOR_TOLERANCE
    end

    def test_saturation
      assert_in_delta 0.2, @hsl.s, Color::COLOR_TOLERANCE
      assert_in_delta 20, @hsl.saturation, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.saturation = 33 }
      assert_in_delta 0.33, @hsl.s, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.s = 3.3 }
      assert_in_delta 100, @hsl.saturation, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.s = -3.3 }
      assert_in_delta 0.0, @hsl.s, Color::COLOR_TOLERANCE
    end

    def test_luminance
      assert_in_delta 0.3, @hsl.l, Color::COLOR_TOLERANCE
      assert_in_delta 30, @hsl.luminosity, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.luminosity = 33 }
      assert_in_delta 0.33, @hsl.l, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.l = 3.3 }
      assert_in_delta 100, @hsl.lightness, Color::COLOR_TOLERANCE
      assert_nothing_raised { @hsl.l = -3.3 }
      assert_in_delta 0.0, @hsl.l, Color::COLOR_TOLERANCE
    end

    def test_html_css
      assert_equal "hsl(145.00, 20.00%, 30.00%)", @hsl.css_hsl
      assert_equal "hsla(145.00, 20.00%, 30.00%, 1.00)", @hsl.css_hsla
    end

    def test_to_cmyk
      cmyk = nil
      assert_nothing_raised { cmyk = @hsl.to_cmyk }
      assert_kind_of Color::CMYK, cmyk
      assert_in_delta 0.3223, cmyk.c, Color::COLOR_TOLERANCE
      assert_in_delta 0.2023, cmyk.m, Color::COLOR_TOLERANCE
      assert_in_delta 0.2723, cmyk.y, Color::COLOR_TOLERANCE
      assert_in_delta 0.4377, cmyk.k, Color::COLOR_TOLERANCE
    end

    def test_to_grayscale
      gs = nil
      assert_nothing_raised { gs = @hsl.to_grayscale }
      assert_kind_of Color::GreyScale, gs
      assert_in_delta 30, gs.gray, Color::COLOR_TOLERANCE
    end

    def test_to_rgb
      rgb = nil
      assert_nothing_raised { rgb = @hsl.to_rgb }
      assert_kind_of Color::RGB, rgb
      assert_in_delta 0.24, rgb.r, Color::COLOR_TOLERANCE
      assert_in_delta 0.36, rgb.g, Color::COLOR_TOLERANCE
      assert_in_delta 0.29, rgb.b, Color::COLOR_TOLERANCE
      assert_equal "#3d5c4a", @hsl.html
      assert_equal "rgb(24.00%, 36.00%, 29.00%)", @hsl.css_rgb
      assert_equal "rgba(24.00%, 36.00%, 29.00%, 1.00)", @hsl.css_rgba
      # The following tests address a bug reported by Jean Krohn on June 6,
      # 2006 and excercise some previously unexercised code in to_rgb.
      assert_equal Color::RGB::Black, Color::HSL.new(75, 75, 0)
      assert_equal Color::RGB::White, Color::HSL.new(75, 75, 100)
      assert_equal Color::RGB::Gray80, Color::HSL.new(75, 0, 80)

      # The following tests a bug reported by Adam Johnson on 29 October
      # 2007.
      rgb = Color::RGB.from_fraction(0.34496, 0.1386, 0.701399)
      c = Color::HSL.new(262, 67, 42).to_rgb
      assert_in_delta rgb.r, c.r, Color::COLOR_TOLERANCE, "Red"
      assert_in_delta rgb.g, c.g, Color::COLOR_TOLERANCE, "Green"
      assert_in_delta rgb.b, c.b, Color::COLOR_TOLERANCE, "Blue"
    end

    def test_to_yiq
      yiq = nil
      assert_nothing_raised { yiq = @hsl.to_yiq }
      assert_kind_of Color::YIQ, yiq
      assert_in_delta 0.3161, yiq.y, Color::COLOR_TOLERANCE
      assert_in_delta 0.0, yiq.i, Color::COLOR_TOLERANCE
      assert_in_delta 0.0, yiq.q, Color::COLOR_TOLERANCE
    end

    def test_mix_with
      red     = Color::RGB::Red.to_hsl
      yellow  = Color::RGB::Yellow.to_hsl
      assert_in_delta 0, red.hue, Color::COLOR_TOLERANCE
      assert_in_delta 60, yellow.hue, Color::COLOR_TOLERANCE
      ry25 = red.mix_with yellow, 0.25
      assert_in_delta 15, ry25.hue, Color::COLOR_TOLERANCE
      ry50 = red.mix_with yellow, 0.50
      assert_in_delta 30, ry50.hue, Color::COLOR_TOLERANCE
      ry75 = red.mix_with yellow, 0.75
      assert_in_delta 45, ry75.hue, Color::COLOR_TOLERANCE
    end

    def test_inspect
      assert_equal "HSL [145.00 deg, 20.00%, 30.00%]", @hsl.inspect
    end
  end
end
