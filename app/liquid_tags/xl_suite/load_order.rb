#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadOrder < Liquid::Tag
    UuidSyntax = /uuid:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:uuid] = $1 if markup =~ UuidSyntax
      @options[:in] = $1 if markup =~ InSyntax

      raise SyntaxError, "Missing uuid: parameter in #{markup.inspect}" unless @options[:uuid]
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      returning "" do
        current_account = context.current_account
        order = current_account.orders.find_by_uuid(context[@options[:uuid]])
        context.scopes.last[@options[:in]] = order.to_liquid
      end
    end
  end
end
