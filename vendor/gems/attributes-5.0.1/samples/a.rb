#
# basic usage is like attr, but note that attribute defines a suite of methods
#
  require 'attributes'

  class C
    attribute 'a'
  end

  c = C.new

  c.a = 42
  p c.a                 #=> 42
  p 'forty-two' if c.a? #=> 'forty-two'

#
# attributes works on object too 
#
  o = Object.new
  o.attribute 'answer' => 42
  p o.answer           #=> 42
