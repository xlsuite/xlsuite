#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: individual-i.rb 92 2005-06-13 19:32:37Z austin $
#++
begin
  require 'pdf/writer'
rescue LoadError => le
  if le.message =~ %r{pdf/writer$}
    $LOAD_PATH.unshift("../lib")
    require 'pdf/writer'
  else
    raise
  end
end

require 'color/palette/monocontrast'

class IndividualI
  def initialize(size = 100)
    @size = size
  end

    # The size of the "i" in points.
  attr_accessor :size

  def half_i(pdf)
    pdf.move_to(0, 82)
    pdf.line_to(0, 78)
    pdf.line_to(9, 78)
    pdf.line_to(9, 28)
    pdf.line_to(0, 28)
    pdf.line_to(0, 23)
    pdf.line_to(18, 23)
    pdf.line_to(18, 82)
    pdf.fill
  end
  private :half_i

  def draw(pdf, x, y)
    pdf.save_state
    pdf.translate_axis(x, y)
    pdf.scale_axis(1 * (@size / 100.0), -1 * (@size / 100.0))

    pdf.circle_at(20, 10, 7.5)
    pdf.fill

    half_i(pdf)

    pdf.translate_axis(40, 0)
    pdf.scale_axis(-1, 1)

    half_i(pdf)

    pdf.restore_state
  end
end

pdf = PDF::Writer.new
ii  = IndividualI.new(24)

x   = pdf.absolute_left_margin
y   = pdf.absolute_top_margin

bg  = Color::RGB.from_fraction(rand, rand, rand)
fg  = Color::RGB.from_fraction(rand, rand, rand)
pal = Color::Palette::MonoContrast.new(bg, fg)

sz  = 24

(-5..5).each do |col|
  pdf.fill_color pal.background[col]
  ii.draw(pdf, x, y)
  ii.size += sz
  x += sz / 2.0
  y -= sz / 2.0
  pdf.fill_color pal.foreground[col]
  ii.draw(pdf, x, y)
  x += sz / 2.0
  y -= sz / 2.0
  ii.size += sz
end

pdf.save_as("individual-i.pdf")
