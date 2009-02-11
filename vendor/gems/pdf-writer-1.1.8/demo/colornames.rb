#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: colornames.rb 134 2005-08-25 03:38:06Z austin $
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

require 'color/rgb/metallic'

pdf = PDF::Writer.new

pdf.start_columns 4

colours = Color::RGB.constants.sort

colours.each do |colour|
  next if colour == "PDF_FORMAT_STR"
  next if colour == "Metallic"
  pdf.fill_color  Color::RGB.const_get(colour)
  pdf.text        colour, :font_size => 24
  pdf.fill_color  Color::RGB::Black
  pdf.text        colour, :font_size => 12, :justification => :center
end

colours = Color::RGB::Metallic.constants.sort
colours.each do |colour|
  pdf.fill_color  Color::RGB::Metallic.const_get(colour)
  pdf.text        colour, :font_size => 24
  pdf.fill_color  Color::RGB::Black
  pdf.text        colour, :font_size => 12, :justification => :center
end

pdf.save_as "colornames.pdf"
