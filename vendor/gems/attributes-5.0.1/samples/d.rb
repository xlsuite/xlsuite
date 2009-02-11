#
# a nice feature is that all attributes are enumerated in the class.  this,
# combined with the fact that the getter method is defined so as to delegate
# to the setter when an argument is given, means bulk initialization and/or
# attribute traversal is very easy.
#
  require 'attributes'

  class C
    attributes %w( x y z )

    def attributes
      self.class.attributes
    end

    def initialize
      attributes.each_with_index{|a,i| send a, i}
    end

    def to_hash
      attributes.inject({}){|h,a| h.update a => send(a)}
    end

    def inspect
      to_hash.inspect
    end
  end

  c = C.new
  p c.attributes 
  p c 

  c.x 'forty-two' 
  p c.x
