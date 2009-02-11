#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
#   Images used in this demo are copyright 2004 - 2005 Why the Lucky Stiff
#   and are from "Why's (Poignant) Guide to Ruby" at
#   <http://poignantguide.net/ruby> with permission.
#
# $Id: chunkybacon.rb 117 2005-07-01 16:48:26Z austin $
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

pdf = PDF::Writer.new
pdf.select_font "Times-Roman"
pdf.text "Chunky Bacon!!", :font_size => 72, :justification => :center

i0 = pdf.image "../images/chunkybacon.jpg", :resize => 0.75
i1 = pdf.image "../images/chunkybacon.png", :justification => :center, :resize => 0.75
pdf.image i0, :justification => :right, :resize => 0.75

pdf.text "Chunky Bacon!!", :font_size => 72, :justification => :center

pdf.save_as("chunkybacon.pdf")
