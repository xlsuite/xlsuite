#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: gettysburg.rb 96 2005-06-15 21:38:38Z austin $
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

GETTYSBURG = <<-'EOS'
Four score and seven years ago our fathers brought forth on this
continent a new nation, conceived in liberty and dedicated to the
proposition that all men are created equal. Now we are engaged in
a great civil war, testing whether that nation or any nation so
conceived and so dedicated can long endure. We are met on a great
battlefield of that war. We have come to dedicate a portion of
that field as a final resting-place for those who here gave their
lives that that nation might live. It is altogether fitting and
proper that we should do this. But in a larger sense, we cannot
dedicate, we cannot consecrate, we cannot hallow this ground.
The brave men, living and dead who struggled here have consecrated
it far above our poor power to add or detract. The world will
little note nor long remember what we say here, but it can never
forget what they did here. It is for us the living rather to be
dedicated here to the unfinished work which they who fought here
have thus far so nobly advanced. It is rather for us to be here
dedicated to the great task remaining before us—that from these
honored dead we take increased devotion to that cause for which
they gave the last full measure of devotion—that we here highly
resolve that these dead shall not have died in vain, that this
nation under God shall have a new birth of freedom, and that
government of the people, by the people, for the people shall
not perish from the earth.
EOS

gba = GETTYSBURG.split($/).join(" ").squeeze(" ")

pdf.text "The Gettysburg Address\n\n", :font_size => 36,
  :justification => :center

y0 = pdf.y + 18
pdf.text gba, :justification => :full, :font_size => 14, :left => 50,
  :right => 50
pdf.move_pointer(36)
pdf.text "U.S. President Abraham Lincoln, 19 November 1863",
  :justification => :right, :right => 100
pdf.text "Gettysburg, Pennsylvania", :justification => :right, :right => 100

pdf.rounded_rectangle(pdf.left_margin + 25, y0, pdf.margin_width - 50,
                      y0 - pdf.y + 18, 10).stroke

pdf.save_as("gettysburg.pdf")
