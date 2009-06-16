require 'rubygems'
require 'hoe'
$:.unshift(File.dirname(__FILE__) + "/lib")
require 'hmac'

Hoe.new('ruby-hmac', HMAC::VERSION) do |p|
  p.name = "ruby-hmac"
  p.author = ["Daiki Ueno", "Geoffrey Grosenbach"]
  p.email = 'boss@topfunky.com'
  p.summary = "An implementation of the HMAC authentication code in Ruby."
  p.description = "A MAC provides a way to check the integrity of information transmitted over or stored in an unreliable medium, based on a secret key."
  p.url = "http://ruby-hmac.rubyforge.org"
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = '' # Release to root
end

desc "Simple require on packaged files to make sure they are all there"
task :verify => :package do
  # An error message will be displayed if files are missing
  if system %(ruby -e "require 'pkg/ruby-hmac-#{HMAC::VERSION}/lib/hmac'")
    puts "\nThe library files are present"
  end
end

task :release => :verify
