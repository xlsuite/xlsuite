require 'rubygems'

SPEC = Gem::Specification.new do |s|
	s.name     = 'rets4r'
	s.version  = '0.8.3'
	s.author   = 'Scott Patterson'
	s.email    = 'scott.patterson@digitalaun.com'
	s.homepage = 'http://rets4r.rubyforge.org/'
	s.rubyforge_project = 'rets4r'
	s.platform = Gem::Platform::RUBY
	s.summary  = 'A native Ruby implementation of RETS (Real Estate Transaction Standard).'
	candidates = Dir.glob("{doc,examples,lib,test}/**/*")
	s.files    = candidates.delete_if do |item|
	               item[0,1] == '.' || item.include?('rdoc')
	             end
	s.require_path     = 'lib'
	s.test_file        = 'test/ts_all.rb'
	s.has_rdoc         = true
	s.rdoc_options     << '--main' << 'README'
  s.extra_rdoc_files = ['CONTRIBUTORS', 'README', 'LICENSE', 'RUBYS', 'GPL', 'CHANGELOG', 'TODO']
end