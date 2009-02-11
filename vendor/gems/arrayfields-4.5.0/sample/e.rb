require 'arrayfields'

Entry = Array.struct :path, :stat

entry = Entry[ File.basename(__FILE__), File.stat(__FILE__) ]
p entry[:path]   #=> "e.rb"
p entry.path     #=> "e.rb"

entry.path = 'foo'
p entry[:path]   #=> "foo"
p entry.path     #=> "foo"

entry.path 'bar' # getter acts as setter without args
p entry['path']  #=> "bar"
p entry.path     #=> "bar"
