#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class GoogleAnalytics < Liquid::Tag
    TheCode = %Q`
        <script type="text/javascript">
          var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
          document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
        </script>
        <script type="text/javascript">
          var pageTracker = _gat._getTracker("____UA_ACCOUNT");
          pageTracker._initData();
          pageTracker._trackPageview();
        </script>
      `.gsub(/^\s+/, "").freeze

    QuotedFragment = Liquid::QuotedFragment.freeze
    UserAgentSyntax = /agent:\s*(#{QuotedFragment})/i.freeze
    def initialize(tag_name, markup, tokens)
      super

      @ua_code = strip_quotes($1.strip) if markup =~ UserAgentSyntax
      raise SyntaxError, "google_analytics requires the agent: parameter" if @ua_code.blank?
    end

    def render(context)
      context_options = Hash.new
      context_options[:agent] = context[@ua_code]
      context_options[:agent] = @ua_code unless context_options[:agent]
      
      TheCode.sub("____UA_ACCOUNT", context_options[:agent].to_s)
    end

    def strip_quotes(value)
      case value[0,1]
      when '"', "'"
        value[1..-2]
      else
        value
      end
    end
  end
end
