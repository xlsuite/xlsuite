#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "action_view/helpers/sanitize_helper"
require "action_view/helpers/tag_helper"
require "action_view/helpers/text_helper"
require "action_view/helpers/url_helper"
require "white_list_helper"

module XlSuite
  class RenderFeed < Liquid::Tag
    extend ActionView::Helpers::SanitizeHelper::ClassMethods
    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::UrlHelper
    include WhiteListHelper
    
    DefaultOptions = {:count => 5, :order => 'random', :display => 'summary', :date_format => 'text'}.freeze
    LabeledSyntax = /labeled[:=]\s*(['"])(.*?)\1/i.freeze
    CountSyntax = /count[:=]\s*(\d+)/i.freeze
    OrderSyntax = /order[:=]\s*(['"])*(random|by_date)\1*/i.freeze
    TaggedAllSyntax = /tagged_all[:=]\s*(['"])(.*?)\1/i.freeze
    TaggedAnySyntax = /tagged_any[:=]\s*(['"])(.*?)\1/i.freeze
    DashboardSyntax = /myfeeds/i.freeze
    DisplaySyntax = /display[:=]\s*(['"])*(title|dash|summary|full)\1*/i.freeze
    TruncateSyntax = /truncate_to[:=]\s*(\d+)/i.freeze
    DisableLinkSyntax =  /disable_link[:=]\s*(['"]*)yes\1/i.freeze
    DateFormatSyntax = /date_format[:=]\s*(['"])*(text|numeric)\1*/i.freeze

    def initialize(tag_name, markup, tokens)
      super

      @options = DefaultOptions.dup
      markup.gsub!(/&quot;/i,'"')
      markup.gsub!("&#8221;", '"')
      
      @options[:labeled] = $2 if markup =~ LabeledSyntax
      @options[:tagged_all] = $2 if markup =~ TaggedAllSyntax
      @options[:tagged_any] = $2 if markup =~ TaggedAnySyntax
      @options[:count] = ($1).to_i if markup =~ CountSyntax
      @options[:order] = $2 if markup =~ OrderSyntax
      @options[:display] = $2 if markup =~ DisplaySyntax
      @options[:truncate_to] = ($1).to_i if markup =~ TruncateSyntax
      @options[:myfeeds] = true if markup =~ DashboardSyntax
      @options[:disable_link] = true if markup =~ DisableLinkSyntax
      @options[:date_format] = $2 if markup =~ DateFormatSyntax

      @options[:date_format] = case @options[:date_format]
        when 'numeric'
          "%Y - %m - %d"
        when 'text'
          "%B %d, %Y"
        end

      raise SyntaxError.new("Render feed syntax error: Can contain only one of myfeeds, labeled, tagged_all or tagged_any options")\
        if ( @options.has_key?(:myfeeds) && (@options.has_key?(:labeled) || @options.has_key?(:tagged_any) || @options.has_key?(:tagged_all)))
      raise SyntaxError.new("Render feed syntax error: Can contain only one of labeled, tagged_all or tagged_any options")\
        if !@options.has_key?(:myfeeds) && (( @options.has_key?(:labeled) && (@options.has_key?(:tagged_any) || @options.has_key?(:tagged_all)) )\
          || (@options.has_key?(:tagged_any) && @options.has_key?(:tagged_all)))
      raise SyntaxError.new("Render feed syntax error: Need to specify any of labeled, tagged_all or tagged_any")\
        if !@options.has_key?(:myfeeds) && !@options.has_key?(:labeled) && !@options.has_key?(:tagged_all) && !@options.has_key?(:tagged_any)
      raise SyntaxError, "@options[:display] has an unexpected value: #{@options[:display].inspect}"\
        if @options[:display] !~ /title|dash|full|summary/i
      raise SyntaxError, "@options[:order] has an unexpected value: #{@options[:order].inspect}"\
        if @options[:order] !~ /random|by_date/i
    end

    def render(context)
      begin
        account = context.current_account
        user = context.current_user
        feeds = []
        feeds << account.feeds.find_by_label(@options[:labeled]) if @options[:labeled]
        feeds += account.feeds.find_tagged_with(:all => Tag.parse(@options[:tagged_all])) if @options[:tagged_all]
        feeds += account.feeds.find_tagged_with(:any => Tag.parse(@options[:tagged_any])) if @options[:tagged_any]
        feeds += user.feeds.find(:all) if @options[:myfeeds] && user.respond_to?(:feeds)
        return "Feed not found" if feeds.compact.blank? 
        feed_items = feeds.map {|f| f.entries.find(:all, :conditions => ["account_id = ?", account.id])}.flatten

        selected_feed_items = case @options[:order]
        when /random/i
          feed_items.sort_by {|_| rand}[0, @options[:count]]
        when /by_date/i
          feed_items.sort_by {|e| e.published_at}.reverse[0, @options[:count]]
        end
        display_method = case @options[:display]
        when /title/i
          :format_title
        when /dash/i
          :format_dash_title
        when /full/i
          :format_content
        when /summary/i
          :format_summary
        end
  
        html = selected_feed_items.map do |item|
          self.send(display_method, item)
        end
 
        if @options[:display] =~ /title/i
          html.unshift %Q(<ul class="feedItems">)
          html.push %Q(</ul>)
        end
        if !(@options[:display]  =~ /dash/i)
          html.map!{|fragment| sanitize(fragment).gsub("&amp;", "&").gsub("&lt;", "<").gsub("&gt;", ">")}
        end
        html
      rescue REXML::ParseException
        "Bad feed data"
      end
    end

    protected
    def format_dash_title(item)
      <<-EOF
        <a onclick="xl.createTab('#{item.link}');return false;" href="#">#{item.title}</a>
      EOF
    end
    
    def format_title(item)
      title_element = link_to(item.title, item.link)
      title_element = item.title if @options[:disable_link] 
      <<-EOF
        <li>
            #{title_element}
        </li>
      EOF
    end

    def format_summary(item)
      content = item.summary.blank? ? item.content : item.summary
      content = strip_tags(content)
      content = truncate(content, @options[:truncate_to]) if @options[:truncate_to]
      
      title_element = link_to(item.title, item.link)
      read_more_element = link_to("more", item.link)
      if @options[:disable_link]
        title_element = item.title
        read_more_element = ""  
      end
      
      <<-EOF
        <div class="feedItem">
          <h3>
            #{title_element}
          </h3>
          <p class="publishedDate">#{item.published_at.strftime(@options[:date_format])}</p>
          <div id="#{item.id}" class="content truncated">
              #{content}
            #{read_more_element}
          </div>
        </div>
      EOF
    end

    def format_content(item)
      title_element = link_to(item.title, item.link)
      title_element = item.title if @options[:disable_link] 
      <<-EOF
        <div class="feedItem">
          <h3>
            #{title_element}
          </h3>
          <p class="publishedDate">#{item.published_at.strftime(@options[:date_format])}</p>
          <div id="#{item.id}" class="content">
            #{item.content}
          </div>
        </div>
      EOF
    end
  end
end
