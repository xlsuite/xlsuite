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
require 'color/palette/gimp'

module TestColor
  module TestPalette
    class TestGimp < Test::Unit::TestCase
      include Color::Palette

      GIMP_W3C = <<-EOS
GIMP Palette
Name: W3C Named Colors
Columns: 2
#
# ColorZilla W3C Named Colors
#
255 255 255 	White
255 255 0 	Yclow	
255 0 255 	Fuchsia
255 0 0		Red
192 192 192	Silver
128 128 128 	Gray
128 128 0	Olive	
128 0 128	Purple
128 0 0		Maroon
0 255 255	Aqua
0 255 0		Lime
0 128 128	Teal
0 128 0		Green
0 0 255		Blue
0 0 128		Navy
0 0 0 		Black 
      EOS

      def setup
        @filename = "test#{Process.pid}.gimp"
      end

      def teardown
        require 'fileutils'
        FileUtils.rm_f @filename if File.exist? @filename
      end

      def test_each
        @gimp = Gimp.new(GIMP_W3C)
        assert_equal(16, @gimp.instance_variable_get(:@colors).size)
        @gimp.each { |c| assert_kind_of(Color::RGB, c) }
      end

      def test_each_name
        @gimp = Gimp.new(GIMP_W3C)
        assert_equal(16, @gimp.instance_variable_get(:@names).size)
        
        @gimp.each_name { |color_name, color_set|
          assert_kind_of(Array, color_set)
          color_set.each { |c|
            assert_kind_of(Color::RGB, c)
          }
        }
      end

      def test_index
        assert_nothing_raised do
          File.open(@filename, "wb") do |f|
            f.write GIMP_W3C
          end
        end
        assert_nothing_raised { @gimp = Gimp.from_file(@filename) }
        assert_equal(Color::RGB::White, @gimp[0])
        assert_equal(Color::RGB::White, @gimp["White"][0])
        assert_equal([Color::RGB::White, Color::RGB::Black],
                     @gimp.values_at(0, -1))
        assert_equal(16, @gimp.size)
      end

      def test_valid_eh
        @gimp = Gimp.new(GIMP_W3C)
        assert(@gimp.valid?)
      end

      def test_name
        @gimp = Gimp.new(GIMP_W3C)
        assert_equal("W3C Named Colors", @gimp.name)
      end
    end
  end
end
