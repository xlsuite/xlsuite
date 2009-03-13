#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "fileutils"

module Zip
  class UnzipError < StandardError; end

  # Represents a Zip archive.
  class Archive
    include FileUtils

    def initialize(file)
      @file = file
    end

    # Unzips this file to +path+.  +path+ will be created if it
    # doesn't already exist.  If an exception occurs during unzippping,
    # all created files will be removed.  +path+ will still exist if an
    # error occurs.
    #
    # WARNING: This method always replaces existing files.
    def unzip_to(path)
      begin
        mkdir_p(path)
        stdout = `unzip -o #{@file} -d #{path}`
        raise Zip::UnzipError, "Could not unzip, process returned #{$?.exitstatus}\n#{stdout}" unless [0, 1].include?($?.exitstatus)
      rescue
        # Clean up after ourselves: delete all created files, but
        # not the path that was handed down to us
        rm_rf(Dir[File.join(path, "*")])
        raise
      end
    end
  end
end
