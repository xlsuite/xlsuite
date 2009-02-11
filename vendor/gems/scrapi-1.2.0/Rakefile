require "benchmark"
require "rubygems"
Gem::manage_gems
require "rake"
require "rake/testtask"
require "rake/rdoctask"
require "rake/gempackagetask"



desc "Generate documentation"
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "Scraper"
  rdoc.options << "--line-numbers"
  rdoc.options << "--inline-source"
  rdoc.rdoc_files.include("README")
  rdoc.rdoc_files.include("lib/**/*.rb")
end


desc "Run all tests"
Rake::TestTask.new(:test) do |test|
  test.libs << "lib"
  test.pattern = "test/**/*_test.rb"
  test.verbose = true
end


desc "Package as a Gem"
gem_spec = Gem::Specification.new do |spec|

  version = nil
  File.readlines("CHANGELOG").each do |line|
    if line =~ /Version (\d+\.\d+\.\d+)/
      version = $1
      break
    end
  end
  raise RuntimeError, "Can't find version number in changelog" unless version

  spec.name = "scrapi"
  spec.version = version
  spec.summary = "scrAPI toolkit for Ruby. Uses CSS selectors to write easy, maintainable HTML scraping rules."
  spec.description = <<-EOF
scrAPI is an HTML scraping toolkit for Ruby. It uses CSS selectors to write easy, maintainable scraping rules to select, extract and store data from HTML content.
EOF
  spec.author = "Assaf Arkin"
  spec.email = "assaf.arkin@gmail.com"
  spec.homepage = "http://blog.labnotes.org/category/scrapi/"

  spec.files = FileList["{test,lib}/**/*", "README", "CHANGELOG", "Rakefile", "MIT-LICENSE"].to_a
  spec.require_path = "lib"
  spec.autorequire = "scrapi.rb"
  spec.requirements << "Tidy"
  spec.add_dependency "tidy",  ">=1.1.0"
  spec.has_rdoc = true
  spec.rdoc_options << "--main" << "README" << "--title" <<  "scrAPI toolkit for Ruby" << "--line-numbers"
  spec.extra_rdoc_files = ["README"]
  spec.rubyforge_project = "scrapi"
end

gem = Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end
