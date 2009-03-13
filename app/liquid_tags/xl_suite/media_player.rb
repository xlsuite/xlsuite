#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class MediaPlayer < Liquid::Tag
    ShockwavePlayerCode = %Q`
      <object id="__ID" width="__WIDTH" height="__HEIGHT" align="__ALIGN" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=__VERSION,0,0,0" classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000">
        <param value="__URL" name="movie"/>
        <param value="high" name="quality"/>
        <param value="__BGCOLOR" name="bgcolor"/>
        <embed width="__WIDTH" height="__HEIGHT" align="__ALIGN" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" allowscriptaccess="sameDomain" me="__ID" bgcolor="__BGCOLOR" quality="high" src="__URL"></embed>
      </object>`.gsub(/^\s+/, "").freeze

    FlashPlayerAutoPlayCode = %Q`
      <object id="__ID" width="__WIDTH" height="__HEIGHT" align="__ALIGN" data="/flash_player_manual.swf?cp=__URL">
        <param value="/flash_player_autoplay.swf?cp=__URL" name="movie"/>
        <param value="true" name="allowFullScreen"/>
        <param value="high" name="quality"/>
        <param value="transparent" name="wmode"/>
        <embed width="__WIDTH" height="__HEIGHT" align="__ALIGN" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" allowscriptaccess="sameDomain" me="__ID" bgcolor="__BGCOLOR" quality="high" src="/flash_player_autoplay.swf?cp=__URL"></embed>
      </object>`.gsub(/^\s+/, "").freeze

    FlashPlayerManualCode = %Q`
      <object id="__ID" width="__WIDTH" height="__HEIGHT" align="__ALIGN" data="/flash_player_manual.swf?cp=__URL">
        <param value="/flash_player_manual.swf?cp=__URL" name="movie"/>
        <param value="true" name="allowFullScreen"/>
        <param value="high" name="quality"/>
        <param value="transparent" name="wmode"/>
        <embed width="__WIDTH" height="__HEIGHT" align="__ALIGN" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" allowscriptaccess="sameDomain" me="__ID" bgcolor="__BGCOLOR" quality="high" src="/flash_player_manual.swf?cp=__URL"></embed>
      </object>`.gsub(/^\s+/, "").freeze

    Mp3PlayerCode = %Q`
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" id="__ID" width="__WIDTH" height="__HEIGHT" align="__ALIGN" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0">
        <param name="allowScriptAccess" value="sameDomain" />
        <param name="movie" value="/mp3_player.swf?path=__URL" />
        <param name="quality" value="high" />
        <param name="__BGCOLOR" value="#ffffff" />
        <embed src="/mp3_player.swf?path=__URL" quality="high" bgcolor="__BGCOLOR" width="__WIDTH" height="__HEIGHT" name="audio" align="__ALIGN" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
      </object>`.gsub(/^\s+/, "").freeze


    QuotedFragment = Liquid::QuotedFragment.freeze
    DefaultOptions = {:version => "7", :align => "middle", :bgcolor => '#000000',
        :id => "", :width => "500", :height => "300"}.freeze

    TypeSelectionSyntax = /flv|mp3|swf/i.freeze

    AlignSyntax = /align:\s*(#{QuotedFragment})/i.freeze
    BgcolorSyntax = /bgcolor:\s*(#{QuotedFragment})/i.freeze
    HeightSyntax = /height:\s*(#{QuotedFragment})/i.freeze
    IdSyntax = /id:\s*(#{QuotedFragment})/i.freeze
    UrlSyntax = /url:\s*(#{QuotedFragment})/i.freeze
    VersionSyntax = /version:\s*(#{QuotedFragment})/i.freeze
    WidthSyntax = /width:\s*(#{QuotedFragment})/i.freeze
    TypeSyntax = /type:\s*(#{QuotedFragment})/i.freeze
    AutoPlaySyntax = /autoplay:\s*(#{QuotedFragment})/i.freeze

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
      @options[:type] = strip_quotes($1) if TypeSyntax =~ markup
      @options[:autoplay] = strip_quotes($1) if AutoPlaySyntax =~ markup

      raise SyntaxError, "media_player tag requires the type: parameter" if @options[:type].blank?
      raise SyntaxError, "the type parameter only supports flv, mp3 and swf" unless @options[:type] =~ TypeSelectionSyntax
      raise SyntaxError, "media_player tag requires the url: parameter" if @options[:url].blank?
    end

    def render(context)
      code = case @options[:type]
        when /flv/i
          if @options[:autoplay] && @options[:autoplay] =~ /yes/i
            FlashPlayerAutoPlayCode
          else
            FlashPlayerManualCode
          end
        when /swf/i
          ShockwavePlayerCode
        when /mp3/i
          Mp3PlayerCode
        else
          raise SyntaxError, "you shouldn't be seeing this message in the first place, please contact the admin"
        end

      returning code.dup do |text|
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
