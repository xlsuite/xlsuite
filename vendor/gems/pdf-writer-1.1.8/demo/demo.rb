#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: demo.rb 134 2005-08-25 03:38:06Z austin $
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

if ARGV.empty?
  line = 'Ruby Rocks'
else
  line = ARGV.join(" ")
end

pdf = PDF::Writer.new

  # Do some funky stuff in the background, in a nice light blue, which is
  # bound to clash with something and some red for the hell of it
x   = 578
r1  = 25

40.step(1, -3) do |xw|
  tone = 1.0 - (xw / 40.0) * 0.2

  pdf.stroke_style(PDF::Writer::StrokeStyle.new(xw))
  pdf.stroke_color(Color::RGB.from_fraction(tone, 1, tone))
  pdf.circle_at(50, 750, r1).stroke
  r1 += xw
end

40.step(1, -3) do |xw|
  tone = 1.0 - (xw / 40.0) * 0.2

  pdf.stroke_style(PDF::Writer::StrokeStyle.new(xw))
  pdf.stroke_color(Color::RGB.from_fraction(tone, tone, 1))
  pdf.line(x, 0, x, 842)
  x = (x - xw - 2)
end

pdf.stroke_color(Color::RGB::Black)
pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
pdf.rectangle(20, 20, 558, 802)

y = 800
50.step(5, -5) do |size|
  height = pdf.font_height(size)
  y = y - height

  pdf.add_text(30, y, line, size)
end

(0...360).step(20) do |angle|
  pdf.fill_color(Color::RGB.from_fraction(rand, rand, rand))

  pdf.add_text(300 + Math.cos(PDF::Math.deg2rad(angle)) * 40,
               300 + Math.sin(PDF::Math.deg2rad(angle)) * 40,
               line, 20, angle)
end

pdf.save_as("demo.pdf")
