require 'arrayfields'
#
# the Arrayfields.new method is a contruct that takes evenly numbered pairs of
# arbitrary objects and builds up a fielded array
#
  a = Arrayfields.new :key, :value, :a, :b
  p a.fields                                     #=> [:key, :a]
  p a.values                                     #=> [:value, :b]
#
# you can use a hash - but of course the ordering gets lost in the initial
# hash creation.  aka the order of fields get horked by the unorderedness of
# ruby's hash iteration.  it's okay for some purposes though
#
  a = Arrayfields.new :key => :value, :a => :b
  p a.fields                                     #=> [:key, :a]
  p a.values                                     #=> [:value, :b]
#
# lists of pairs get flattened - the argument simply has to be evenly numbered
# afterwards.
#
  a = Arrayfields.new [[:key, :value], [:a, :b]]
  p a.fields                                     #=> [:key, :a]
  p a.values                                     #=> [:value, :b]
  p a.pairs                                      #=> [[:key, :value], [:a, :b]]
  
