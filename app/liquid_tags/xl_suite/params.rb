#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class Params < Liquid::Tag
    PositionSyntax = /pos(?:ition)?:\s*(\d+)/i
    NameSyntax = /name:\s*(['"])([-\w\[\]]+)\1/i

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:position] = Integer($1) if markup =~ PositionSyntax
      @options[:name] = $2.downcase if markup =~ NameSyntax

      raise SyntaxError, "Only one of NAME or POSITION must be specified.  Found #{@options.inspect}" if @options.keys.size > 1
      raise SyntaxError, "Must specify one of NAME or POSITION: none specified in #{markup.inspect}" if @options.keys.empty?
    end

    def render(context)
      if @options[:position] then
        (context.registers["page_url"] || "").sub(%r{https?://}, '').split('/')[@options[:position]]
      elsif @options[:name] then
        (context.registers["params"] || {})[@options[:name]]
      else
        raise SyntaxError, "No position or name specified"
      end
    end
  end
end
