#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadSnippets < Liquid::Tag   
    InSyntax = /in:\s*([\w_]+)/
    TitleSyntax = /title:\s*(#{Liquid::QuotedFragment})/
    DomainPattern = /domain_pattern:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    
    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new

      @options[:in] = $1 if markup =~ InSyntax
      @options[:title] = $1 if markup =~ TitleSyntax
      @options[:order] = $1 if markup =~ OrderSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:title]].flatten.compact
      raise SyntaxError, "title: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      current_account = context.current_account

      context_options = Hash.new
      options = Hash.new
      
      [:title, :order].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end
      
      orders = []
      if @options[:order]
        orders << context_options[:order]
      else
        orders << "created_at DESC"
      end

      options.merge!(:order => orders.join(",")) unless orders.blank?

      
      context[@options[:in]] = current_account.snippets.find_all_by_title(context_options[:title], options)
      nil
    end
  end
end
