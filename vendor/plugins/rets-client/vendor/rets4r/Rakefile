require "rubygems"
require "rake"
require "rake/clean"
require "rake/testtask"
require "rake/packagetask"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/contrib/rubyforgepublisher"
require "fileutils"
include FileUtils

task :default => :test

desc "Run unit tests"
Rake::TestTask.new("test") do |t|
  t.libs << "test"
  t.test_files = ["test/ts_all.rb"]
  t.verbose = true
end
