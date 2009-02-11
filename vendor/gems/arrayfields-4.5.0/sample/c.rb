require 'arrayfields'
#
# the Array.fields methods generates an instance with those fields
#
  a = Array.fields :a, :b, :c
  a[:a] = a[:c] = 42
  p a                           #=> [42, nil, 42]
  p a.fields                    #=> [:a, :b, :c]
  p a.values                    #=> [42, nil, 42]
