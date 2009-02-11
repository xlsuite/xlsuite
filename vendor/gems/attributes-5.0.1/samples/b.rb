#
# default values may be given either directly or as a block which will be
# evaluated in the context of self.  in both cases (value or block) the
# default is set only once and only if needed - it's a lazy evaluation.  the
# 'banger' method can be used to re-initialize a variable at any point whether
# or not it's already been initialized.
#
  require 'attributes'

  class C
    attribute :a => 42
    attribute(:b){ Float a }
  end

  c = C.new
  p c.a #=> 42
  p c.b #=> 42.0

  c.a = 43
  p c.a #=> 43
  c.a!
  p c.a #=> 42
