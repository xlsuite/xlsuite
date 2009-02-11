# Ruby interface to HTML Tidy Library Project (http://tidy.sf.net).
#
# =Usage
#
#   require 'tidy'
#   Tidy.path = '/usr/lib/tidylib.so'
#   html = '<html><title>title</title>Body</html>'
#   xml = Tidy.open(:show_warnings=>true) do |tidy|
#     tidy.options.output_xml = true
#     puts tidy.options.show_warnings
#     xml = tidy.clean(html)
#     puts tidy.errors
#     puts tidy.diagnostics
#     xml
#   end
#   puts xml
#
# Author::  Kevin Howe
# License:: Distributes under the same terms as Ruby
#
module Tidy

  require 'dl/import'
  require 'dl/struct'
  require 'tidy/tidybuf'
  require 'tidy/tidyerr'
  require 'tidy/tidylib'
  require 'tidy/tidyobj'
  require 'tidy/tidyopt'

  module_function

  # Return a Tidyobj instance.
  #
  def new(options=nil)
    Tidyobj.new(options)
  end
  
  # Path to Tidylib.
  #
  def path() @path end
  
  # Set the path to Tidylib (automatically loads the library).
  #
  def path=(path)
    Tidylib.load(path)
    @path = path
  end
  
  # With no block, open is a synonym for Tidy.new.
  # If a block is present, it is passed aTidy as a parameter.
  # aTidyObj.release is ensured at end of the block.
  #
  def open(options=nil)
    raise "Tidy.path was not specified." unless @path
    tidy = Tidy.new(options)
    if block_given?
      begin
        yield tidy
      ensure
        tidy.release
      end
    else
      tidy
    end
  end
  
  # Convert to boolean.
  # 0, false and nil return false, anything else true.
  #
  def to_b(value)
    [0,false,nil].include?(value) ? false : true
  end

end
