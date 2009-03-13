#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadSnippet < Liquid::Tag
    TitleSyntax = /title:\s*(#{Liquid::QuotedFragment})/
    
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:title] = $1 if markup =~ TitleSyntax
      @options[:in] = $1 if markup =~ InSyntax

      raise SyntaxError, "Please specify :title options for load_snippet" unless @options[:title]
      
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      current_account = context.current_account

      context_options = Hash.new
      
      [:title].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end
      
      context[@options[:in]] = current_account.snippets.find_all_by_title(context_options[:title]).best_match_for_domain(context.current_domain)
      nil
    end
  end
end
