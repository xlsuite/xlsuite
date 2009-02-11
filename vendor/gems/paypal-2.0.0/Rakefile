require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

PKG_VERSION = "2.0.0"
PKG_NAME = "paypal"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

PKG_FILES = FileList[
    "lib/**/*", 
    "test/*", 
    "misc/*", 
    "[A-Z]*", 
    "MIT-LICENSE",
    "Rakefile"
].exclude(/\bCVS\b|~$/)

desc "Default Task"
task :default => [ :test, :test_remote ]

desc "Delete tar.gz / zip / rdoc"
task :cleanup => [ :rm_packages, :clobber_rdoc ]

# Run the unit tests
Rake::TestTask.new :test do |t|
  t.libs << "test"
  t.pattern = 'test/*_test.rb'
  t.ruby_opts << '-rubygems'
  t.verbose = false
end

Rake::TestTask.new :test_remote do |t|
  t.libs << "test"
  t.pattern = 'test/remote/*_test.rb'
  t.ruby_opts << '-rubygems'
  t.verbose = false
end

desc "Create a rubygem and install it. Might need root rights"
task :install => [:package] do
  `gem install pkg/#{PKG_FILE_NAME}.gem`
end

# Genereate the RDoc documentation

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Paypal library"
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
}

task :lines do
  lines = 0
  codelines = 0
  Dir.foreach("lib") { |file_name| 
    next unless file_name =~ /.*rb/

    f = File.open("lib/" + file_name)

    while line = f.gets
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
  }
  puts "Lines #{lines}, LOC #{codelines}"
end


desc "Publish the gem on leetsoft"
task :publish => [:rdoc, :package] do
 Rake::SshFilePublisher.new("leetsoft.com", "dist/pkg", "pkg", "#{PKG_FILE_NAME}.zip").upload
 Rake::SshFilePublisher.new("leetsoft.com", "dist/pkg", "pkg", "#{PKG_FILE_NAME}.tgz").upload
 Rake::SshFilePublisher.new("leetsoft.com", "dist/gems", "pkg", "#{PKG_FILE_NAME}.gem").upload
 `ssh tobi@leetsoft.com "mkdir -p dist/api/#{PKG_NAME}"`
 Rake::SshDirPublisher.new("leetsoft.com", "dist/api/#{PKG_NAME}", "doc").upload
 `ssh tobi@leetsoft.com './gemupdate'`
end

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION  
  s.description = s.summary = "Paypal IPN integration library for rails and other web applications"
  s.has_rdoc = true

  s.files = %w(init.rb README Rakefile MIT-LICENSE) + Dir['lib/**/*'] + Dir['misc/**/*'] + Dir['test/**/*']
  s.files.reject! { |f| /\/\.\_/ }
  s.require_path = 'lib'
  s.autorequire  = 'paypal'
  s.author = "Tobias Luetke"
  s.email = "tobi@leetsoft.com"
  s.homepage = "http://dist.leetsoft.com/api/paypal"  
  
  s.add_dependency('money')
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end


# --- Ruby forge release manager by florian gross -------------------------------------------------

RUBY_FORGE_PROJECT = 'paypal'
RUBY_FORGE_USER = 'xal'
RELEASE_NAME  = "REL #{PKG_VERSION}"

desc "Publish the release files to RubyForge."
task :release => [:publish] do
  `rubyforge login`
  release_command = "rubyforge add_release #{PKG_NAME} #{PKG_NAME} 'REL #{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.gem"
  puts release_command
  system(release_command)

  release_command = "rubyforge add_release #{PKG_NAME} #{PKG_NAME} 'REL #{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.zip"
  puts release_command
  system(release_command)

end
