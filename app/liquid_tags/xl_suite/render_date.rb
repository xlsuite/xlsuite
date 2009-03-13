#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class RenderDate < Liquid::Tag
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::TagHelper

    DisplaySelectionSyntax = /date_and_day|date_only/
    
    DefaultOptions = {:display => "date_and_day"}.freeze
    DisplaySyntax = /display[:=]\s*(['"]*)(.*?)\1/i.freeze

    def initialize(tag_name, markup, tokens)
      super

      @options = DefaultOptions.dup
      markup.gsub!(/&quot;/i,'"')
      markup.gsub!("&#8221;", '"')
      
      @options[:display] = $2 if markup =~ DisplaySyntax

      raise SyntaxError, "Render date syntax error options[:display] has an unexpected value: #{@options[:display].inspect}"\
        if @options[:display] !~ /(#{DisplaySelectionSyntax})/i
    end

    def render(context)
      time = Time.now
      case @options[:display]
      when /date_and_day/i
        %Q!<p class="current_date">#{time.strftime("%A, %B %d, %Y")}</p>!
      when /date_only/i
        %Q!<p class="current_date">#{time.strftime("%B %d, %Y")}</p>!
      end
    end
  end
end
