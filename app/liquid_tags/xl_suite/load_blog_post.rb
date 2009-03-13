#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadBlogPost < Liquid::Tag
    IdSyntax = /id:\s*(#{Liquid::QuotedFragment})/
    AccessDeniedSyntax = /access_denied:\s*(#{Liquid::QuotedFragment})/
    GroupLabelsSyntax = /group_labels:\s*(#{Liquid::QuotedFragment})/
    
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:id] = $1 if markup =~ IdSyntax
      @options[:in] = $1 if markup =~ InSyntax
      @options[:access_denied] = $1 if markup =~ AccessDeniedSyntax
      @options[:group_labels] = $1 if markup =~ GroupLabelsSyntax

      raise SyntaxError, "Please specify :id options for load_blog_post" unless @options[:id]
      
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      current_account = context.current_account

      context_options = Hash.new
      
      [:id, :access_denied, :group_labels].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end

      blog_post = current_account.blog_posts.find(context_options[:id])
      
      now = Time.now.utc
      out = blog_post if context.current_user? ? blog_post.writeable_by?(context.current_user) : (blog_post.published_at && (blog_post.published_at <= now))
      
      if context.current_user? 
        if @options[:access_denied]
          context[@options[:access_denied]] = !blog_post.blog.readable_by?(context.current_user) 
        else 
          out = nil if !blog_post.blog.readable_by?(context.current_user) 
        end
      else
        if @options[:access_denied]
          context[@options[:access_denied]] = blog_post.blog.private?
        else
          out = nil if blog_post.blog.private?
        end
      end
      
      if @options[:group_labels]
        context[@options[:group_labels]] = blog_post.blog.readers.map(&:label)
      end
      
      context[@options[:in]] = out
      return (blog_post.published_at && (blog_post.published_at <= now)) ? "Access Denied" : "Blog post is not published" if out.nil?
      nil
    end
  end
end
