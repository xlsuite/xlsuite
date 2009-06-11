#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "open-uri"
require "set"

class SiteImportFuture < SpiderFuture
  before_create :default_to_star_star_domain_patterns
  validate :presence_of_domain_patterns
  validate :presence_of_title

  def prepare
    status!(:initializing)

    self.results[:pages] = Hash.new
    self.results[:imported_assets_count] = 0
    self.results[:imported_pages_count] = 0
    self.results[:candidates] = Set.new
    self.results[:assets] = Hash.new
    self.results[:truncated_items] = Set.new
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
    when /xhtml/
      process_html(uri, page, xhtml_layout)
    when /html/
      process_html(uri, page, html_layout)
    when /javascript/
      process_javascript(uri, page, javascript_layout)
    when /css/
      process_stylesheet(uri, page, css_layout)
    when /image/
      process_asset(uri, page)
    when /text/
      process_text(uri, uri, page, text_layout)
    else
      process_asset(uri, page)
    end
  end

  def process_asset(uri, page)
    new_uri = download_asset(uri)
    generate_redirect(uri, uri.merge(new_uri))
  end

  def process_javascript(uri, page, layout)
    process_text(uri, uri, page, layout)
  end

  def process_stylesheet(uri, page, layout)
    page.body = rewrite_css_url_descriptors(uri, page.body)
    process_text(uri, uri, page, layout)
  end

  def rewrite_css_url_descriptors(uri, body)
    body.gsub(/url\((?:'([^']+)'|"([^"]+)"|(.+?))\)/) do |relative_url|
      relative_uri = uri.merge(URI.parse($1 || $2 || $3)) rescue nil
      next relative_url if relative_uri.nil? || relative_uri.host != root.host

      image_uri = uri.merge(relative_uri)
      new_uri = download_asset(image_uri)
      "url(#{new_uri})"
    end
  end

  def process_html_inline_styles(uri, page)
    page.search("//style[@type=text/css]").each do |style|
      style.inner_html = rewrite_css_url_descriptors(uri, style.inner_html)
    end
  end

  def process_html_areas(uri, page)
    each_html_element_with_attribute_on_same_domain(uri, page, "area", "href") do |anchor, relative_uri|
      anchor["href"] = relative_uri.path
    end
  end

  def process_html_anchors(uri, page)
    each_html_element_with_attribute_on_same_domain(uri, page, "a", "href") do |anchor, relative_uri|
      anchor["href"] = relative_uri.path
    end
  end

  def process_html_images(uri, page)
    each_html_element_with_attribute_on_same_domain(uri, page, "img", "src") do |img, image_uri|
      img["src"] = download_asset(image_uri)
    end
  end

  def process_html(uri, page, layout)
    process_html_images(uri, page) # Download images and rewrite the HTML to use the new URL on XLsuite
    process_html_inline_styles(uri, page) # Rewrite the style to change URL references to the XLsuite URLs
    process_html_anchors(uri, page) # Rewrite anchors to use relative URLs instead of absolute ones
    process_html_areas(uri, page) # Rewrite areas to use relative URLs instead of absolute ones

    fullslug = root.merge(URI.parse(calculate_nice_slug(uri)))
    page = process_text(uri, fullslug, page, layout)

    redirect = generate_redirect(uri, fullslug)
    self.pages[uri.to_s] = {page.fullslug => redirect.target} if redirect

    self.results[:imported_pages_count] += 1
  end

  def calculate_nice_slug(uri)
    fullslug = uri - root
    fullslug = fullslug.path.sub(File.extname(fullslug.path), "")
    fullslug.sub!(/\/index$/, "") if fullslug =~ /\/index$/
    fullslug = "/" if fullslug.empty?
    fullslug
  end

  def generate_redirect(original_uri, target_uri)
    return if original_uri == target_uri
    self.account.redirects.create!(
      :status => "published",
      :fullslug => original_uri.path,
      :target => target_uri.path,
      :domain_patterns => domain_patterns,
      :creator => owner)
  end

  def process_text(uri, fullslug, page, layout)
    title = case
            when page.respond_to?(:title)
              page.title
            else
              uri.to_s
            end
    page_body = page.respond_to?(:parser) ? page.parser.to_s : page.body
    if page_body.size > Item::MAXIMUM_BODY_LENGTH
      #page_body = page_body[0, Item::MAXIMUM_BODY_LENGTH]
      page_body = "Original page #{uri.to_s} is more than 512 kb"
      self.results[:truncated_items] << uri.to_s
    end
    self.account.pages.create!(
      :status => "published",
      :fullslug => fullslug.path,
      :body => page_body,
      :title => title || uri.path,
      :layout => layout.title,
      :domain_patterns => domain_patterns,
      :creator => owner)
  end

  def finalize
    status!(:done, 100)
  end

  def download_asset(asset_uri)
    return assets[asset_uri.to_s] if assets.include?(asset_uri.to_s)

    begin
      asset = self.account.assets.create!(:temp_data => open(asset_uri).read,
                                          :filename => File.basename(asset_uri.path),
                                          :owner => self.owner)
      self.results[:imported_assets_count] += 1
      assets[asset_uri.to_s] = "/z/#{asset.filename}"
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
    @html_layout ||= self.account.layouts.create!(:title => args[:title] + " HTML", :content_type => "text/html", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :creator => owner)
  end

  def text_layout
    @text_layout ||= self.account.layouts.create!(:title => args[:title] + " Text", :content_type => "text/plain", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :creator => owner)
  end

  def xhtml_layout
    @xhtml_layout ||= self.account.layouts.create!(:title => args[:title] + " XHTML", :content_type => "application/xhtml+xml", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :creator => owner)
  end

  def css_layout
    @css_layout ||= self.account.layouts.create!(:title => args[:title] + " Stylesheet", :content_type => "text/css", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :creator => owner)
  end

  def javascript_layout
    @js_layout ||= self.account.layouts.create!(:title => args[:title] + " JavaScript", :content_type => "text/javascript", :encoding => "UTF-8", :domain_patterns => args[:domain_patterns], :body => "{{ page.body }}", :creator => owner)
  end

  def domain_patterns
    args[:domain_patterns]
  end

  def want_to_spider?(uri)
    results[:candidates] << uri.to_s
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
end
