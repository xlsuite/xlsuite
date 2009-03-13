#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadFolder < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    FolderPathSyntax = /folder_path:\s*(#{Liquid::QuotedFragment})/
    
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:folder_path] = $1 if markup =~ FolderPathSyntax
      @options[:in] = $1 if markup =~ InSyntax

      specifications = [@options[:id], @options[:folder_path]].flatten.compact
      raise SyntaxError, "Please specify either :id or :folder_path options for load_folder" if specifications.size < 1
      
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      current_account = context.current_account

      context_options = Hash.new
      
      [:id, :folder_path].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end
      
      folder = nil
      if @options[:id]
        folder = current_account.folders.find(context_options[:id])
      elsif @options[:folder_path]
        folder = current_account.folders.find_by_path(context_options[:folder_path])
      else
        raise SyntaxError, "Please specify either :id or :folder_path options"
      end
      
      context[@options[:in]] = folder
      nil
    end
  end
end
