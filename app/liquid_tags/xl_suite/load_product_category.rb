#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadProductCategory < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/
    NameSyntax = /name:\s*(#{Liquid::QuotedFragment})/
    LabelSyntax = /label:\s*(#{Liquid::QuotedFragment})/
    
    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:in] = $1 if markup =~ InSyntax
      @options[:name] = $1 if markup =~ NameSyntax
      @options[:label] = $1 if markup =~ LabelSyntax

      specifications = [@options[:name], @options[:id], @options[:label]].flatten.compact
      raise SyntaxError, "One of id: or label: must be specified in #{markup.inspect}" if specifications.size != 1
      
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      returning "" do
        current_account = context.current_account
        if @options[:id]
          product_category = current_account.product_categories.find(context[@options[:id]])
        elsif @options[:name]
          product_category = current_account.product_categories.find_by_name(context[@options[:name]])
        else
          product_category = current_account.product_categories.find_by_label(context[@options[:label]])
        end
        context.scopes.last[@options[:in]] = product_category.to_liquid
      end
    end
  end
end
