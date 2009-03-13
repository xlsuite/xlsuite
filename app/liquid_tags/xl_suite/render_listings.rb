#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "action_view/helpers/text_helper"
require "action_view/helpers/tag_helper"
require "action_view/helpers/url_helper"

module XlSuite
  class RenderListings < Liquid::Tag
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ApplicationHelper
    include ListingsHelper
    include ERB::Util

    FlashCode = %q(<object class="video" width="__WIDTH" height="__HEIGHT" align="__ALIGN"
        codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=__VERSION,0,0,0"
        classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000">
      <param value="__URL" name="movie"/>
      <param value="high" name="quality"/>
      <param value="__BGCOLOR" name="bgcolor"/>
      <embed width="__WIDTH" height="__HEIGHT" align="__ALIGN" pluginspage="http://www.macromedia.com/go/getflashplayer"
          type="application/x-shockwave-flash" allowscriptaccess="sameDomain" bgcolor="__BGCOLOR" quality="high"
          src="__URL"/>
    </object>).gsub(/^\s+/, "").freeze

    QuotedFragment = Liquid::QuotedFragment.freeze

    OrderSelectionSyntax = /random|(date|price|area)_((a|de)sc)/
    DisplaySelectionSyntax = /summary|medium|full/
    ThumbnailSizeSelectionSyntax = /square|mini|small|medium/

    DefaultOptions = {:count => 1000, :display => 'summary', :status => "active",
      :flash => {:version => "7", :align => "middle", :bgcolor => '#00000', :width => "", :height => ""}}.freeze

    # Listing related options
    MlsNoSyntax = /mls_no[:=]\s*(['"])(.*?)\1/i.freeze
    CountSyntax = /count[:=]\s*(\d+)/i.freeze
    OrderSyntax = /order[:=]\s*(['"]*)(.*?)\1/i.freeze
    DomainSyntax = /domain[:=]\s*(['"])(.*?)\1/i.freeze
    DomainPathSyntax = /domain_path[:=]\s*(['"])(.*?)\1/i.freeze
    TaggedAllSyntax = /tagged_all[:=]\s*(['"])(.*?)\1/i.freeze
    TaggedAnySyntax = /tagged_any[:=]\s*(['"])(.*?)\1/i.freeze
    DisplaySyntax = /display[:=]\s*(['"]*)(.*?)\1/i.freeze
    StatusSyntax = /status[:=]\s*(['"]*)(.*?)\1/i.freeze
    ThumbnailSizeSyntax = /thumbnail_size[:=]\s*(['"]*)(.*?)\1/i.freeze

    # Listing flash file related options
    FlashAlignSyntax = /flash_align[:=]\s*(#{QuotedFragment})/i
    FlashBgcolorSyntax = /flash_bgcolor[:=]\s*(#{QuotedFragment})/i
    FlashHeightSyntax = /flash_height[:=]\s*(#{QuotedFragment})/i
    FlashVersionSyntax = /flash_version[:=]\s*(#{QuotedFragment})/i
    FlashWidthSyntax = /flash_width[:=]\s*(#{QuotedFragment})/i

    def initialize(tag_name, markup, tokens)
      super

      @options = DefaultOptions.dup

      markup.gsub!(/&quot;/i,'"')
      markup.gsub!("&#8221;", '"')

      @options[:domain] = $2 if markup =~ DomainSyntax
      @options[:domain_path] = $2 if markup =~ DomainPathSyntax
      @options[:mls_no] = $2 if markup =~ MlsNoSyntax
      @options[:tagged_all] = $2 if markup =~ TaggedAllSyntax
      @options[:tagged_any] = $2 if markup =~ TaggedAnySyntax
      @options[:count] = ($1).to_i if markup =~ CountSyntax

      @options[:order] = $2 if markup =~ OrderSyntax
      @options[:display] = $2 if markup =~ DisplaySyntax
      @options[:status] = $2 if markup =~ StatusSyntax
      @options[:thumbnail_size] = $2 if markup =~ ThumbnailSizeSyntax

      # TODO: should I really be using SyntaxError?? doesn't feel right
      #raise SyntaxError, "Render listings syntax error: Must contain domain option" unless @options.has_key?(:domain)
      raise SyntaxError, "Render listings syntax error: Can contain only one of mls_no, tagged_all or tagged_any options"\
        if ( @options.has_key?(:mls_no) && (@options.has_key?(:tagged_any) || @options.has_key?(:tagged_all)) )\
          || (@options.has_key?(:tagged_any) && @options.has_key?(:tagged_all))
      raise SyntaxError, "Render listings syntax error: Need to specify any of mls_no, tagged_all or tagged_any"\
        if !@options.has_key?(:mls_no) && !@options.has_key?(:tagged_all) && !@options.has_key?(:tagged_any)
      raise SyntaxError, "Render listings syntax error: Order option #{@options[:order]} is invalid"\
        if @options[:order] !~ /(#{OrderSelectionSyntax})/i
      raise SyntaxError, "Render listings syntax error: Display option has an unexpected value of #{@options[:display]}, please use summary or medium or full"\
        if @options[:display] !~ /(#{DisplaySelectionSyntax})/i
      raise SyntaxError, "Render listings syntax error: Thumbnail size option has an unexpected value of #{@options[:thumbnail_size]}, please choose one of square, mini, small or medium"\
        if !@options[:thumbnail_size].blank? && @options[:thumbnail_size] !~ /(#{ThumbnailSizeSelectionSyntax})/i

      @options[:thumbnail_size] = @options[:thumbnail_size].blank? ? :mini : @options[:thumbnail_size].downcase.to_sym

      @options[:flash][:align] = strip_quotes($1) if FlashAlignSyntax =~ markup
      @options[:flash][:bgcolor] = strip_quotes($1) if FlashBgcolorSyntax =~ markup
      @options[:flash][:height] = strip_quotes($1) if FlashHeightSyntax =~ markup
      @options[:flash][:version] = strip_quotes($1) if FlashVersionSyntax =~ markup
      @options[:flash][:width] = strip_quotes($1) if FlashWidthSyntax =~ markup

      @options[:flash_code] = returning FlashCode.dup do |text|
        @options[:flash].each_pair do |key, value|
          text.gsub!("__#{key.to_s.upcase}", value)
        end
      end
    end

    def render(context)
      error_messages = []
      domain = context.current_domain
      domain_name = domain.name

      if @options[:domain]
        domain_name = @options[:domain].dup
        domain = Domain.find_by_name(domain_name)
        domain_name = "www." << domain_name if domain.nil? && @options[:domain] !~ /www\./i
        domain = Domain.find_by_name(domain_name) if domain.nil?
        raise SyntaxError, "Render listings error: Domain not found" if domain.nil?
      end

      account = if domain then domain.account else context.current_account end

      listings = []
      listings << account.listings.find_by_mls_no(@options[:mls_no], :conditions => "public=1") if @options[:mls_no]
      listings += account.listings.find_tagged_with(:all => Tag.parse(@options[:tagged_all]), :conditions => "public=1", :order => "mls_no DESC") if @options[:tagged_all]
      listings += account.listings.find_tagged_with(:any => Tag.parse(@options[:tagged_any]), :conditions => "public=1", :order => "mls_no DESC") if @options[:tagged_any]
      listings = listings.flatten.compact

      status_regex = @options[:status].split(",").map(&:strip).join("|")
      status_regex = Regexp.new(status_regex, true)
      listings.reject!{|e| e.status !~ status_regex} unless @options[:status] =~ /all/i || (@options[:mls_no] && !@options[:tagged_all] && !@options[:tagged_any])

      selected_listings = []
      if @options[:order] =~ /random/i
        selected_listings = listings.sort_by {|_| rand}
      elsif @options[:order] =~ /#{OrderSelectionSyntax}/i
        mode = $2
        selected_listings = case $1
          when /date/i
            listings.sort_by {|e| e.list_date}
          when /price/i
            listings
          when /area/i
            listings.sort_by {|e| e.area}
          end
        selected_listings.reverse! if mode =~ /desc/i
      end

      selected_listings = selected_listings[0, @options[:count]]
      error_messages << "No listing found" if selected_listings.blank?

      display_method = case @options[:display]
      when /summary/i
        :format_summary
      when /medium/i
        :format_medium
      when /full/i
        :format_full
      end

      unless error_messages.blank?
        msg = error_messages.map {|e| "<li>#{e}</li>"}.join("")
        return "<ul class='errorMessages'>#{msg}</ul>"
      end

      domain_home = "http://#{domain_name}"
      domain_path = "/#{@options[:domain_path]}"
      domain_path.gsub!(/\/+/, "/")
      domain_href = "#{domain_home}#{domain_path}"
      html = selected_listings.map do |listing|
        self.send(display_method, listing, domain_home, domain_href, account, context)
      end

      if @options[:display] =~ /summary/i
        html.unshift %Q(<ul class="listingItems">)
        html.push %Q(</ul>)
      end

      html
    end

  protected
    def format_summary(listing, domain_home, domain_href, account, context)
      out = []
      out << "<div class='listing-options'>"
      out << link_to("Google Map", gmap_url(listing.gmap_query))
      out << link_to("Send to a friend", send_to_friend_link(listing, domain_home, context.page_url))
      out << render_add_remove_listings_link(listing, context)
      out << "</div>"
      out << "<li><dl>"
      if listing.pictures.blank?
        out << content_tag(:dt, content_tag(:div, '<img src="/images/no-image_mini.jpg" alt="no description" />'), :class => "picture")
      else
        image_url = "#{domain_home}/" << download_asset_path(:id => listing.pictures.first.id, :size => @options[:thumbnail_size])
        out << content_tag(:dt, link_to("<img src='#{image_url}'>", show_listing_url(domain_home, listing)), :class => "picture")
      end
      out << content_tag(:dd, listing.open_house_text, :class => "listing-open-house") unless listing.open_house_text.blank?
      out << content_tag(:dd, render_listing_address_area_city_and_zip(listing), :class => "address")
      out << content_tag(:dd, render_listing_price(listing.price), :class => "price")
      out << content_tag(:dd, "Listing provided by #{listing.broker}", :class => "brokerage") unless listing.broker.blank?
      out << content_tag(:dd, link_to("More info", show_listing_url(domain_home, listing)), :class => "link")
      out << "</dl></li>"
      out.join("")
    end

    def format_medium(listing, domain_home, domain_href, account, context)
      out = []
      out << "<div id='#{listing.dom_id}' class='propListingWrap'>"
      out << content_tag(:h2, render_listing_address_area_city_and_zip(listing), :class => "listingHeader")
      out << content_tag(:h3, render_listing_size_style_and_price(listing), :class => "listingHeader")
      out << content_tag(:div, listing.open_house_text, :class => "listing-open-house") unless listing.open_house_text.blank?

      out << "<div class='listing-options'>"
      out << link_to("Google Map", gmap_url(listing.gmap_query))
      out << link_to("Send to a friend", send_to_friend_link(listing, domain_home, context.page_url))
      out << link_to("Contact", domain_href)
      out << render_add_remove_listings_link(listing, context)
      out << "</div>"

      out << content_tag(:div, listing.extras, :class => "listing-extras") unless listing.extras.blank?

      out << "<table class='lp'>"
      out << %Q[
            <tr class="spacer">
              <th class="leftColumn"></th>
              <th class="rightColumn"/>
            </tr>
          ]
      out << content_tag(:tr,
          content_tag(:td, "MLS Number", :class => "bold") << content_tag(:td, h(listing.mls_no)) )
      if context.current_user?
        out << content_tag(:tr,
            content_tag(:td, "List Date", :class => "bold") << content_tag(:td, h(listing.list_date)) ) 
        out << content_tag(:tr,
            content_tag(:td, "Last Transaction", :class => "bold") << content_tag(:td, h(listing.last_transaction)) )
      end
      out << content_tag(:tr,
          content_tag(:td, "Status", :class => "bold") << content_tag(:td, h(listing.status)) )
      out << content_tag(:tr,
          content_tag(:td, "Dwelling Type", :class => "bold") << content_tag(:td, h(listing.dwelling_type)) )
      out << content_tag(:tr,
          content_tag(:td, "Dwelling Class", :class => "bold") << content_tag(:td, h(listing.dwelling_class)) )
      out << content_tag(:tr,
          content_tag(:td, "Title of Land", :class => "bold") << content_tag(:td, h(listing.title_of_land)) )
      out << content_tag(:tr,
          content_tag(:td, "Bedrooms/Bathrooms", :class => "bold") << content_tag(:td, render_listing_column(listing.bedrooms, listing.bathrooms)) )
      out << content_tag(:tr,
          content_tag(:td, "Year Built", :class => "bold") << content_tag(:td, h(listing.year_built)) )
      out << content_tag(:tr,
          content_tag(:td, "Images", :class => "bold") << content_tag(:td, h(listing.num_of_images)) )
      out << content_tag(:tr,
          content_tag(:td, "Description", :class => "bold") << content_tag(:td, h(listing.description)) )
      out << content_tag(:tr,
          content_tag(:td, "Listing provided by", :class => "bold") << content_tag(:td, h(listing.broker) + "<img src='/images/reciprocity_small.gif'/>") ) unless listing.broker.blank?
      out << "</table>"

      out << "<div class='propImages'>"
      out << render_listing_thumbnails(listing, domain_home)
      out << render_listing_latest_flash_file(listing, domain_home)
      out << "</div>"
      out << "<br class='clear' />"

      out << "</div>"
      out.join("")
    end

    def format_full(listing, domain_home, domain_href, account, context)
      ""
    end

    def get_contact_link(account, domain_href)
      account_owner = account.owner
      email = account_owner.main_email.email_address
      name = account_owner.full_name.blank? ? "Account Owner" : account_owner.full_name
      link_to(h(name), domain_href)
    end

    def render_listing_latest_flash_file(listing, domain_home)
      flash_file = listing.assets.find(:first, :conditions => "content_type LIKE '%shockwave-flash%'", :order => "created_at DESC")
      return "" unless flash_file
      render_flash(flash_file, domain_home)
    end

    def render_flash(flash_file, domain_home)
      url = "#{domain_home}/#{download_asset_path(:id => flash_file.id)}"
      @options[:flash_code].gsub("__URL", url)
    end

    def download_asset_path(options={})
      return "" if options[:id].blank?
      url = "admin/assets/#{options[:id]};download"
      url << "?size=#{options[:size].to_s}" unless options[:size].blank?
      url
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
