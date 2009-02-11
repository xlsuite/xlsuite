#! /usr/bin/env rake
#--
# Color
# Colour Management with Ruby
# http://rubyforge.org/projects/color
#
# Licensed under a MIT-style licence. See Licence.txt in the main
# distribution for full licensing information.
#
# Copyright (c) 2005 - 2007 Austin Ziegler and Matt Lyon
#
# $Id: History.txt 50 2007-02-03 20:26:19Z austin $
#++

require 'rubygems'
require 'hoe'

$LOAD_PATH.unshift('lib')

require 'color'

PKG_NAME    = 'color'
PKG_VERSION = Color::COLOR_VERSION
PKG_DIST    = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_TAR     = "pkg/#{PKG_DIST}.tar.gz"
MANIFEST    = File.read("Manifest.txt").split

Hoe.new PKG_NAME, PKG_VERSION do |p|
  p.rubyforge_name  = PKG_NAME
  # This is a lie becasue I will continue to use Archive::Tar::Minitar.
  p.need_tar        = false
  # need_zip - Should package create a zipfile? [default: false]

  p.author          = [ "Austin Ziegler", "Matt Lyon" ]
  p.email           = %W(austin@rubyforge.org matt@postsomnia.com)
  p.url             = "http://color.rubyforge.org/"
  p.summary         = "Colour management with Ruby"
  p.changes         = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.description     = p.paragraphs_of("Readme.txt", 1..1).join("\n\n")

  p.extra_deps      << [ "archive-tar-minitar", "~>0.5.1" ]

  p.clean_globs     << "coverage"

  p.spec_extras[:extra_rdoc_files] = MANIFEST.grep(/txt$/) -
    ["Manifest.txt"]
end

desc "Build a Color .tar.gz distribution."
task :tar => [ PKG_TAR ]
file PKG_TAR => [ :test ] do |t|
  require 'archive/tar/minitar'
  require 'zlib'
  files = MANIFEST.map { |f|
    fn = File.join(PKG_DIST, f)
    tm = File.stat(f).mtime

    if File.directory?(f)
      { :name => fn, :mode => 0755, :dir => true, :mtime => tm }
    else
      mode = if f =~ %r{^bin}
               0755
             else
               0644
             end
      data = File.read(f)
      { :name => fn, :mode => mode, :data => data, :size => data.size,
        :mtime => tm }
    end
  }

  begin
    unless File.directory?(File.dirname(t.name))
      require 'fileutils'
      File.mkdir_p File.dirname(t.name)
    end
    tf = File.open(t.name, 'wb')
    gz = Zlib::GzipWriter.new(tf)
    tw = Archive::Tar::Minitar::Writer.new(gz)

    files.each do |entry|
      if entry[:dir]
        tw.mkdir(entry[:name], entry)
      else
        tw.add_file_simple(entry[:name], entry) { |os|
          os.write(entry[:data])
        }
      end
    end
  ensure
    tw.close if tw
    gz.close if gz
  end
end
task :package => [ PKG_TAR ]

desc "Build the manifest file from the current set of files."
task :build_manifest do |t|
  require 'find'

  paths = []
  Find.find(".") do |path|
    next if File.directory?(path)
    next if path =~ /\.svn/
    next if path =~ /\.swp$/
    next if path =~ %r{coverage/}
    next if path =~ /~$/
    paths << path.sub(%r{^\./}, '')
  end

  File.open("Manifest.txt", "w") do |f|
    f.puts paths.sort.join("\n")
  end

  puts paths.sort.join("\n")
end
