#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadGroup < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    NameSyntax = /name:\s*(#{Liquid::QuotedFragment})/
    LabelSyntax = /label:\s*(#{Liquid::QuotedFragment})/
    
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:label] = $1 if markup =~ NameSyntax
      @options[:label] = $1 if markup =~ LabelSyntax
      @options[:in] = $1 if markup =~ InSyntax

      specifications = [@options[:id], @options[:label]].flatten.compact
      raise SyntaxError, "Please specify either :id or :label options for load_group" if specifications.size < 1
      
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      current_account = context.current_account

      context_options = Hash.new
      
      [:id, :label].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end

      group = nil
      if @options[:id]
        group = current_account.groups.find(context_options[:id])
      elsif @options[:label]
        group = current_account.groups.find_by_label(context_options[:label])
      else
        raise SyntaxError, "Please specify either :id or :label options"
      end
      
      context[@options[:in]] = group
      nil
    end
  end
end
