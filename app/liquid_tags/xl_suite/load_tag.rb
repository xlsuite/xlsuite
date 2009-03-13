#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadTag < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    NameSyntax = /name:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:name] = $1 if markup =~ NameSyntax
      @options[:in] = $1 if markup =~ InSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
      raise SyntaxError, "Missing id: or name: parameter in #{markup.inspect}" unless @options[:id] || @options[:name]
    end

    def render(context)
      returning "" do
        current_account = context.current_account
        tag = case
              when @options[:id]
                current_account.tags.find(context[@options[:id]])
              when @options[:name]
                current_account.tags.find_by_name(context[@options[:name]])
              else
                raise ActiveRecord::RecordNotFound, "Could not find Tag because an unrecognized option was provided: #{@options.keys}"
              end
        context.scopes.last[@options[:in]] = tag.to_liquid
      end
    end
  end
end
