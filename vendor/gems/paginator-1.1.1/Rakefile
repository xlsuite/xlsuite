# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/paginator.rb'

Hoe.new('paginator', Paginator::VERSION) do |p|
  p.rubyforge_name = 'paginator'
  p.summary = 'A generic paginator object for use in any Ruby program'
  p.description =<<EOD
Paginator doesn't make any assumptions as to how data is retrieved; you just
have to provide it with the total number of objects and a way to pull a specific
set of objects based on the offset and number of objects per page.  
EOD
  p.url = "http://paginator.rubyforge.org"
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.email = %q{bruce@codefluency.com}
  p.author = ["Bruce Williams"]
end

# vim: syntax=Ruby
