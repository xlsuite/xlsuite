require 'attributes'

module M
  p(( attribute 'a' => 42 ))
  p(( attribute('b'){ "forty-two (#{ self })" } ))
end
p M.attributes
p M.attributes.include?('a')
p M.attributes.include?('b')
p M.attributes.include?('c')

class C
  include M
end
p C.new.a
p C.new.b
p C.attributes
p C.attributes.include?('a')
p C.attributes.include?('b')
p C.attributes.include?('c')

class B < C
end
p B.new.a
p B.new.b
p B.attributes
p B.attributes.include?('a')
p B.attributes.include?('b')
p B.attributes.include?('c')
