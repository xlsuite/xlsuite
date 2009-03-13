#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadProduct < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    OwnerIdSyntax = /owner_id:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:owner_id] = $1 if markup =~ OwnerIdSyntax
      @options[:in] = $1 if markup =~ InSyntax

      raise SyntaxError, "Missing id: parameter in #{markup.inspect}" unless @options[:id]
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      returning "" do
        current_account = context.current_account
        context_options = Hash.new
        [:id, :owner_id].each do |option_sym|
          context_options[option_sym] = context[@options[option_sym]]
          context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
        end

        conditions = {:id => context_options[:id]}
        conditions.merge!(:owner_id => context_options[:owner_id])if @options[:owner_id]
        product = current_account.products.find(:first, :conditions => conditions)
        context.scopes.last[@options[:in]] = product.to_liquid
      end
    end
  end
end
