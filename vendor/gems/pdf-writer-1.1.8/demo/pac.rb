#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: pac.rb 134 2005-08-25 03:38:06Z austin $
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

pdf = PDF::Writer.new(:orientation => :landscape)

pdf.fill_color    Color::RGB::Black
pdf.rectangle(0, 0, pdf.page_width, pdf.page_height).fill

  # Wall
pdf.fill_color    Color::RGB::Magenta
pdf.stroke_color  Color::RGB::Cyan
pdf.rounded_rectangle(20, 500, 750, 20, 10).close_fill_stroke
pdf.rounded_rectangle(20, 200, 750, 20, 10).close_fill_stroke

  # Body
pdf.fill_color    Color::RGB::Yellow
pdf.stroke_color  Color::RGB::Black
pdf.circle_at(150, 350, 100).fill_stroke

  # Mouth
pdf.fill_color    Color::RGB::Black
pdf.segment_at(150, 350, 100, 100, 30, -30).close_fill_stroke

  # Dot
pdf.fill_color    Color::RGB::Yellow
pdf.circle_at(250, 350, 20).fill_stroke
pdf.circle_at(300, 350, 10).fill_stroke
pdf.circle_at(350, 350, 10).fill_stroke
pdf.circle_at(400, 350, 10).fill_stroke
pdf.circle_at(450, 350, 10).fill_stroke

pdf.fill_color    Color::RGB::Blue
pdf.stroke_color  Color::RGB::Cyan
pdf.move_to(500, 250)
pdf.line_to(500, 425)
pdf.curve_to(550, 475, 600, 475, 650, 425)
pdf.line_to(650, 250)
pdf.line_to(625, 275)
pdf.line_to(600, 250)
pdf.line_to(575, 275)
pdf.line_to(550, 250)
pdf.line_to(525, 275)
pdf.line_to(500, 250).fill_stroke

pdf.fill_color    Color::RGB::White
pdf.rectangle(525, 375, 25, 25).fill
pdf.rectangle(575, 375, 25, 25).fill
pdf.fill_color    Color::RGB::Black
pdf.rectangle(525, 375, 10, 10).fill
pdf.rectangle(575, 375, 10, 10).fill

pdf.save_as("pac.pdf")
