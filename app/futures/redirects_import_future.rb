#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "open-uri"
require "set"

class RedirectsImportFuture < SpiderFuture
  before_create :default_to_star_star_domain_patterns
  validate :presence_of_domain_patterns

  def prepare
    status!(:initializing)

    self.results[:redirects] = Hash.new
    self.results[:failed_redirects] = []
    self.results[:imported_redirects_count] = 0
    self.results[:failed_redirects_count] = 0
    self.results[:candidates] = Set.new
    self.results[:assets] = Hash.new
  end

  def redirects
    @redirects ||= self.results[:redirects]
  end
  
  def failed_redirects
    @failed_redirects ||= self.results[:failed_redirects]
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
      self.process_redirect(uri)
    when /html/
      self.process_redirect(uri)
    end
  end

  def process_redirect(uri)
    fullslug = uri.path
    return nil if ["/", "/admin", "/sessions/new", "/sessions", "/sessions/destroy", "/login", "/logout"].include?(fullslug)
    redirect = self.account.redirects.build(
      :status => "published",
      :fullslug => fullslug,
      :target => "/",
      :domain_patterns => domain_patterns,
      :creator => owner)
    created = redirect.save
    if created
      self.redirects[fullslug] = redirect.id 
      self.results[:imported_redirects_count] += 1
    else
      self.failed_redirects << fullslug
      self.results[:failed_redirects_count] += 1
    end
  end

  def finalize
    status!(:done, 100)
  end

  protected
  def default_to_star_star_domain_patterns
    self.args[:domain_patterns] = "**" if self.args[:domain_patterns].blank?
  end

  def presence_of_domain_patterns
    return if self.new_record? # before_create will set **
    errors.add_to_base("domain_patterns missing") if self.args[:domain_patterns].blank?
  end

  def domain_patterns
    args[:domain_patterns]
  end

  def want_to_spider?(uri)
    results[:candidates] << uri.to_s
    super
  end
end
