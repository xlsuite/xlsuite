#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class Flash < Liquid::Tag
    TheCode = %q(<object id="__ID" width="__WIDTH" height="__HEIGHT" align="__ALIGN" type="application/x-shockwave-flash" data="__URL">
      <param value="__URL" name="movie"/>
      <param value="__ALLOW_FULL_SCREEN" name="allowFullScreen"/>
      <param value="high" name="quality"/>
      <param value="__WMODE" name="wmode"/>
      <param value="__BGCOLOR" name="bgcolor"/>
    </object>).gsub(/^\s+/, "").freeze

    QuotedFragment = Liquid::QuotedFragment.freeze
    DefaultOptions = {:version => "7", :align => "middle", :bgcolor => '#00000',
        :id => "", :width => "", :height => "", :allow_full_screen => "true", :wmode => "transparent"}.freeze

    AlignSyntax = /align:\s*(#{QuotedFragment})/i
    BgcolorSyntax = /bgcolor:\s*(#{QuotedFragment})/i
    HeightSyntax = /height:\s*(#{QuotedFragment})/i
    IdSyntax = /id:\s*(#{QuotedFragment})/i
    UrlSyntax = /url:\s*(#{QuotedFragment})/i
    VersionSyntax = /version:\s*(#{QuotedFragment})/i
    WidthSyntax = /width:\s*(#{QuotedFragment})/i
    AllowFullScreenSyntax = /allow_full_screen:\s*(#{QuotedFragment})/i
    WModeSyntax = /wmode:\s*(#{QuotedFragment})/i

    def initialize(tag_name, markup, tokens)
      super

      @options = DefaultOptions.dup
      @options[:align] = strip_quotes($1) if AlignSyntax =~ markup
      @options[:bgcolor] = strip_quotes($1) if BgcolorSyntax =~ markup
      @options[:height] = strip_quotes($1) if HeightSyntax =~ markup
      @options[:id] = strip_quotes($1) if IdSyntax =~ markup
      @options[:url] = strip_quotes($1) if UrlSyntax =~ markup
      @options[:version] = strip_quotes($1) if VersionSyntax =~ markup
      @options[:width] = strip_quotes($1) if WidthSyntax =~ markup
      @options[:allow_full_screen] = strip_quotes($1) if AllowFullScreenSyntax =~ markup
      @options[:wmode] = strip_quotes($1) if WModeSyntax =~ markup

      raise SyntaxError, "flash tag requires the url: parameter: it is missing" if @options[:url].blank?
    end

    def render(context)
      returning TheCode.dup do |text|
        temp_value = nil
        @options.each_pair do |key, value|
          temp_value = context[value]
          logger.debug {"PRE (#{key.inspect} => #{value.inspect})\n\n#{text}"}
          text.gsub!("__#{key.to_s.upcase}", (temp_value || value).to_s)
          logger.debug {"POST\n\n#{text}"}
        end
      end
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
