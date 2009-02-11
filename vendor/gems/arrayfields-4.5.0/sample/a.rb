require 'arrayfields'
#
# the class Array has only a few added method, one is for setting the fields,
# when the fields are set for an array THIS INSTANCE ONLY will be modified to
# allow keyword access.  other arrays will not be affected!
#
  a = [0,1,2]
  fields = ['zero', 'one', 'two']
  a.fields = fields                # ONLY the Array 'a' is affected!
#
# keyword access is now allowed for many methods
#
  p a['zero']                        #=> 0
  p a['one']                         #=> 1
  p a['two']                         #=> 2
  p a.at('one')                      #=> 1
  p a.values_at('zero', 'two')       #=> [0, 2]
#
# assigmnet is allowed
#
  a['zero'] = 42
  p a['zero']                        #=> 42 
#
# assignment to non-fields results in the element being appended and the field
# being added for future use (also appended)
#
  p(a.fields.join(','))                 #=> "zero, one, two"
  p a['three']                          #=> nil
  a['three'] = 3
  p(a.fields.join(','))                 #=> "zero, one, two, three"
  p a['three']                          #=> 3 
#
# other detructive methods are also keyword enabled
#
  a.fill 42, 'zero', len = a.size
  p(a.values_at(a.fields))              #=> [42, 42, 42, 42]
  a.replace [0,1,2,3]

  a.slice! 'two', 2 
  p a                                   #=> [0,1] 
