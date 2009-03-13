#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadAffiliate < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:in] = $1 if markup =~ InSyntax

      raise SyntaxError, "Missing id: parameter in #{markup.inspect}" unless @options[:id]
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      returning "" do
        current_account = context.current_account
        affiliate = current_account.affiliates.find(context[@options[:id]])
        context.scopes.last[@options[:in]] = affiliate.to_liquid
      end
    end
  end
end
