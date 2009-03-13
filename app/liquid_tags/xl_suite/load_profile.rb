#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadProfile < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::VariableSignature}+)/
    AliasSyntax = /alias:\s*(#{Liquid::QuotedFragment})/
    CustomUrlSyntax = /custom_url:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(\w+)/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:alias] = $1 if markup =~ AliasSyntax
      @options[:custom_url] = $1 if markup =~ CustomUrlSyntax
      @options[:in] = $1 if markup =~ InSyntax
    end

    def render(context)
      current_account = context.current_account
      context_options = Hash.new

      [:id, :alias, :custom_url].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end

      profile = nil
      if @options[:id]
        profile = current_account.profiles.find(context_options[:id])
      elsif @options[:alias]
        profile = current_account.profiles.find_by_alias(context_options[:alias])
      elsif @options[:custom_url]
        profile = current_account.profiles.find_by_custom_url(context_options[:custom_url])
      end
      unless profile
        context.scopes.last[@options[:in]] = nil
        return "No profile created for this contact"
      end
      
      context.scopes.last[@options[:in]] = profile.to_liquid
      return ""
    end
  end
end
