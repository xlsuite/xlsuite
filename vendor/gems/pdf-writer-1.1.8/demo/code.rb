#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# The code in this file is highly experimental and is not generally ready
# for use. I can't figure out why the stuff *after* is so far to the right.
# I'll need to play with the X position some to get it right. This will NOT
# make it into the 1.0 release. Maybe 1.1 or 1.2.
#
# $Id: code.rb 92 2005-06-13 19:32:37Z austin $
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

class TagCodeFont
  FONT_NAME       = "Courier"
  FONT_ENCODING   = nil
  FONT_SIZE_DIFF  = 0.9

  class << self
    attr_accessor :font_name

    def [](pdf, info)
      @font_name          ||= FONT_NAME
      @font_encoding      ||= FONT_ENCODING

      case info[:status]
      when :start, :start_line
        @__fontinfo ||= {}
        @__fontinfo[info[:cbid]] = {
          :font       => pdf.current_font,
          :base_font  => pdf.current_base_font,
          :info       => info
        }

        pdf.select_font(@font_name, @font_encoding)

        { :font_change => true }
      when :end, :end_line
        fi = @__fontinfo[info[:cbid]]

        pdf.font_size = fi[:font_size]
        pdf.select_font(fi[:base_font])
        pdf.select_font(fi[:font])
      end
    end
  end
end

PDF::Writer::TAGS[:pair]["code"] = TagCodeFont

pdf.text "Hello, <c:code>Ruby</c:code>.", :font_size => 72, :justification => :center
pdf.move_pointer(80)
pdf.text "This is a longer <c:code>sample of code font text</c:code>. What do you think?", :font_size => 12, :justification => :full

pdf.save_as("code.pdf")
