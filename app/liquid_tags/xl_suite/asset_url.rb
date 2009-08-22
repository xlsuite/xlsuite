#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class AssetUrl < Liquid::Tag
    FilePathSyntax = /file_path:\s*(#{Liquid::QuotedFragment})/
    SizeSyntax = /size:\s*(?:['"])?(square|mini|small|medium|large|full)(?:['"])?\b/i.freeze
    
    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      markup.gsub!(/&quot;/i,'"')
      markup.gsub!("&#8221;", '"')
      @options[:file_path] = $1 if markup =~ FilePathSyntax
      @options[:size] = $1 if markup =~ SizeSyntax

      raise SyntaxError, "AssetUrl: Expected file_path option to be set in #{markup.inspect}" if @options[:file_path].blank?
    end

    def render(context)
      context_options = Hash.new
      current_account = context.current_account

      [:file_path, :size, :private].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end
      
      return "File path must start with /z/" unless context_options[:file_path].strip =~ /^\/z\//i
      file_path = context_options[:file_path].gsub(/^\/z\//i, "")
      file_path = file_path.split("/")
      name = file_path.pop
      path = file_path.join("/")
      asset = current_account.assets.find_by_path_and_filename(path, name)
      
      asset = asset.find_or_initialize_thumbnail(context_options[:size]) unless (context_options[:size] == "full" || context_options[:size].blank? || asset.blank?)

      if asset
        return asset.private ? asset.authenticated_s3_url : asset.s3_url
      else
        return "No asset found at #{@options[:file_path]}"
      end
    end
  end
end
