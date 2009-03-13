#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "open-uri"
require "set"

#MrdBuildingsImport.create!(:account => Account.find(1932), :owner => Account.find(1932).owner, :args => {:root => "http://mrdowntown.ca", :title => "mrd_buildings_import", :slug_match => "mrdowntown.ca/Building.php\\?BuildingName"})

class MrdBuildingsImport < SpiderFuture
  before_create :default_to_star_star_domain_patterns
  validate :presence_of_domain_patterns
  validate :presence_of_title

  def prepare
    status!(:initializing)
    
    self.results[:pages] = Hash.new
    self.results[:imported_assets_count] = 0
    self.results[:imported_pages_count] = 0
    self.results[:created_views_count] = 0
    self.results[:candidates] = Set.new
    self.results[:assets] = Hash.new
  end

  def run
    self.class.transaction do
      self.update_attribute(:results, {:bad_urls => []})

      self.prepare

      @uris_to_visit = Array.new
      @visited_uris = Set.new

      agent = WWW::Mechanize.new
      uris_to_visit << root

      while uri = uris_to_visit.shift
        visited_uris << uri
        self.remember_uri!(uri)

        begin
          page = agent.get(uri)
          self.process(uri, page)
        rescue WWW::Mechanize::ResponseCodeError, SocketError, SystemCallError
          log_link_error($!, uri)
        end

        each_link_on(uri, page) do |new_uri|
          # Normalize URLs before processing them
          # For example, strip ../ from the path, and make sure the
          # hostname is normalized, so we can compare correctly later
          
          path = new_uri.path
          path = path+'?'+new_uri.query unless new_uri.query.blank?
          new_uri.merge!(URI.parse(Pathname.new(path).cleanpath))
          new_uri.normalize!

          # See if we should visit this URI at a later date
          uris_to_visit << new_uri if want_to_spider?(new_uri)
        end

        uris_to_visit.uniq!
      end

      self.finalize
    end

    complete!
  end

  def pages
    @pages ||= self.results[:pages]
  end

  def process(uri, page)
    if uris_to_visit.length.zero? then
      status!(:importing)
    else
      status!(:importing, (visited_uris.length.to_f / (uris_to_visit.length + visited_uris.length) * 100).floor)
    end

    self.update_attribute(:results, self.results.merge(:current_page_content_type => page.response["content-type"]))
    
    return false if !args[:slug_match].blank? && !(uri.to_s =~ Regexp.new(args[:slug_match]))
    
    case page.response["content-type"]
    when /xml/, /rss/, /rdf/
      # What should we do with XML ?
      # We punt on the issue and do nothing for now.
      return
    when /html/
      process_html(uri, page, html_layout)
    else
      #do nothing
    end
  end

  def process_html_images(uri, page)
    page.search("div#picturebox > a > img") do |img|
      relative_uri = uri.merge(URI.parse(img.attributes["src"].gsub(" ", "%20").gsub("+", "%20")))
      asset = download_asset(relative_uri)
    end
  end

  def process_html(uri, page, layout)
    @profile = self.account.parties.create!
    @profile.company_name = page.at('center > h1').inner_html if page.at('center > h1')
    if page.at('div#textbox')
      if page.at('div#textbox').inner_html =~ /Use the navigation panel below to access floorplans, current listings, and strata plans for this Yaletown Vancouver condo/
        @profile.biography = "Details coming soon"
      else
        @profile.biography = page.at('div#textbox').inner_html 
      end
    end
        
    i=0
    page.search('div#bottombar > ul > li > a').each do |el|
      if i == 0
        @profile.position = el.attributes['href'].gsub('/', '')
        @profile.tag_list = el.attributes['href'].gsub('/', '').gsub(' ', '').underscore + " building, july04"
      elsif el.to_html =~ /View Listings/
        @link = @profile.links.build(:url => el.attributes['href'], :account_id => self.account.id)
        @link.save!
      end
      i = i+1
    end
    
    if page.at('center > p')
      @address = @profile.addresses.build(:line1 => page.at('center > p').inner_html, :city => "Vancouver", :state => "BC", :country => "CAN", :account_id => self.account.id)      
    else
      RAILS_DEFAULT_LOGGER.debug("==> Warning: Address could not be scraped from #{uri.path}")
    end
    @address.save!
    @profile.public_profile = true
    @profile.save!
    
    process_html_images(uri, page) # Download images and rewrite the HTML to use the new URL on XLsuite
    
    self.results[:imported_pages_count] += 1
  end

  def finalize
    status!(:done, 100)
  end

  def download_asset(asset_uri)
    return assets[asset_uri.to_s] if assets.include?(asset_uri.to_s)

    begin
      original_filename = File.basename(asset_uri.path)
      new_filename = @profile.company_name + "." + original_filename.split(".").last
      asset = self.account.assets.create!(:temp_data => open(asset_uri).read,
                                          :filename => new_filename,
                                          :owner => self.owner,
                                          :tag_list => "building")
      self.results[:imported_assets_count] += 1
      if asset
        @profile.views.create!(:asset_id => asset.reload.id)
        self.results[:created_views_count] += 1
      end
    rescue
      logger.warn {"==> Could not open #{asset_uri}: #{$!.message}"}
      asset_uri.to_s
    end
  end

  protected
  def default_to_star_star_domain_patterns
    self.args[:domain_patterns] = "**" if self.args[:domain_patterns].blank?
  end

  def presence_of_domain_patterns
    return if self.new_record? # before_create will set **
    errors.add_to_base("domain_patterns missing") if self.args[:domain_patterns].blank?
  end

  def presence_of_title
    errors.add_to_base("title missing") if self.args[:title].blank?
  end

  def html_layout
    @html_layout ||= self.account.layouts.create!(:title => args[:title] + " HTML", :content_type => "text/html", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :author => owner)
  end

  def text_layout
    @text_layout ||= self.account.layouts.create!(:title => args[:title] + " Text", :content_type => "text/plain", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :author => owner)
  end

  def xhtml_layout
    @xhtml_layout ||= self.account.layouts.create!(:title => args[:title] + " XHTML", :content_type => "application/xhtml+xml", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :author => owner)
  end

  def css_layout
    @css_layout ||= self.account.layouts.create!(:title => args[:title] + " Stylesheet", :content_type => "text/css", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :author => owner)
  end

  def javascript_layout
    @js_layout ||= self.account.layouts.create!(:title => args[:title] + " JavaScript", :content_type => "text/javascript", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :author => owner)
  end

  def domain_patterns
    args[:domain_patterns]
  end

  def want_to_spider?(uri)
    return false if uri.to_s =~ /building\d\.jpg/
    super
  end

  def assets
    results[:assets]
  end

  # Yields elements from +page+ that are +element+ and have a non-nil +attribute+.
  # If the element is a link/reference to something on another domain, the block
  # will *not* be yielded to.
  #
  # == Examples
  #  # Rewrite all AREA tags so that the href attribute is using a relative path, and not an absolute URL.
  #  each_html_element_with_attribute_on_same_domain(uri, page, "area", "href") do |area, target_uri|
  #    area["href"] = target_uri.path
  #  end
  def each_html_element_with_attribute_on_same_domain(uri, page, element, attribute)
    page.search("//#{element}[@#{attribute}]") do |element|
      relative_uri = uri.merge(URI.parse(element[attribute])) rescue nil
      next element if relative_uri.nil? || !same_host?(uri, relative_uri)

      yield element, relative_uri
    end
  end

  def log_link_error(exception, uri, current_link=nil)
    data = current_link.if_not_nil do |link|
      link.respond_to?(:href) ? [link.text, link.href] : link.inspect
    end
    unless exception.message =~ /maps.google.com/
      self.results[:bad_urls] << [uri.to_s, exception.message, data].compact
      self.save!
    end
  end
end
