require 'arrayfields'
#
# the struct class factory method can be used in much the same way as ruby's
# own struct generators and is useful when the fields for a set of arrays is
# known apriori
#
  c = Array.struct :a, :b, :c  # class generator 
  a = c.new [42, nil, nil]
  a[:c] = 42
  p a                          #=> [42, nil, 42]
#
# of course we can append too
#
  a[:d] = 42.0
  p a[:d]                      #=> 42.0
  p a                          #=> [42, nil, 42, 42.0]
