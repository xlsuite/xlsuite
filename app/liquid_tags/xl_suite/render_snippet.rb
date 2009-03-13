#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class RenderSnippet < Liquid::Tag

    TitleSyntax = /title[:=]\s*(['"])(.*?)\1/i.freeze
    SNIPPET_NESTING_DEPTH_KEY = "xlsuite_snippet_nesting_depth".freeze

    def initialize(tag_name, markup, tokens)
      super

      markup.gsub!(/&quot;/i,'"')
      markup.gsub!("&#8221;", '"')
      @title = $2 if markup =~ TitleSyntax
      raise SyntaxError, "#{self.class.name}: must contain a title: attribute" if @title.blank?
    end

    def render(context)
      snippet = context.current_account.snippets.find_by_domain_and_title(context.current_domain, @title)
      return "" if snippet.blank? || !snippet.readable_by?(context.current_user)
      
      context[SNIPPET_NESTING_DEPTH_KEY] ||= Hash.new {|h,k| h[k] = 0}
      context[SNIPPET_NESTING_DEPTH_KEY][snippet.title] += 1
      
      out = ""
      begin
        return out if context[SNIPPET_NESTING_DEPTH_KEY][snippet.title] > 10
        out = snippet.render_body(context)
      ensure
        context[SNIPPET_NESTING_DEPTH_KEY][snippet.title] -= 1
      end
      out
    end
  end
end
