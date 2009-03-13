#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadBlog < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    LabelSyntax = /label:\s*(#{Liquid::QuotedFragment})/
    AccessDeniedSyntax = /access_denied:\s*(#{Liquid::QuotedFragment})/
    GroupLabelsSyntax = /group_labels:\s*(#{Liquid::QuotedFragment})/
    
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:label] = $1 if markup =~ LabelSyntax
      @options[:in] = $1 if markup =~ InSyntax
      @options[:access_denied] = $1 if markup =~ AccessDeniedSyntax
      @options[:group_labels] = $1 if markup =~ GroupLabelsSyntax

      specifications = [@options[:id], @options[:label]].flatten.compact
      raise SyntaxError, "Please specify either :id or :label options for load_blog" if specifications.size < 1
      
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      current_account = context.current_account

      context_options = Hash.new
      
      [:id, :label, :access_denied, :group_labels].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end

      blog = nil
      if @options[:id]
        blog = current_account.blogs.find(context_options[:id])
      elsif @options[:label]
        blog = current_account.blogs.find_by_label(context_options[:label])
      else
        raise SyntaxError, "Please specify either :id or :label options"
      end
      
      if context.current_user? 
        if @options[:access_denied]
          context[@options[:access_denied]] = !blog.readable_by?(context.current_user) 
        else 
          blog = nil if !blog.readable_by?(context.current_user) 
        end
      else
        if @options[:access_denied]
          context[@options[:access_denied]] = blog.private?
        else
          blog = nil if blog.private?
        end
      end
      
      if @options[:group_labels]
        context[@options[:group_labels]] = blog.readers.map(&:label)
      end
      
      context[@options[:in]] = blog
      return "Access Denied" if blog.nil?
      nil
    end
  end
end
