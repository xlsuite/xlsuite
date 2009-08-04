#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "mechanize"
require "set"
require "cgi"

class SpiderFuture < Future
  validate :presence_of_root

  attr_reader :uris_to_visit, :visited_uris

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
          new_uri.merge!(URI.parse(Pathname.new(new_uri.path).cleanpath))
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

  def remember_uri!(uri)
    self.update_attribute(:results, self.results.merge(:current_url => uri.to_s))
  end

  def prepare
  end

  def process(uri, page)
    raise SubclassResponsibilityError, "\#process(uri, page) not implemented in #{self.class.name}"
  end

  def finalize
  end

  def root
    @root ||= URI.parse(args[:root].strip)
  end

  def want_to_spider?(uri)
    self.same_host?(root, uri) && !self.visited_uris.include?(uri)
  end

  def each_link_on(uri, page)
    current_link = nil
    page.links.each do |link|
      begin
        current_link = link
        yield new_link(uri, link.href)
      rescue
        log_link_error($!, uri, current_link)
      end
    end if page.respond_to?(:links)

    current_link = nil
    begin
      page.search("//frame[@src]").each do |link|
        current_link = link
        yield new_link(uri, link["src"])
      end if page.respond_to?(:search)
    rescue
      log_link_error($!, uri, current_link)
    end

    current_link = nil
    begin
      page.search("//area[@href]").each do |link|
        current_link = link
        yield new_link(uri, link["href"])
      end if page.respond_to?(:search)
    rescue
      log_link_error($!, uri, current_link)
    end

    current_link = nil
    begin
      page.search("//head/link[@href][@rel~=stylesheet]").each do |link|
        current_link = link
        yield new_link(uri, link["href"])
      end if page.respond_to?(:search)
    rescue
      log_link_error($!, uri, current_link)
    end

    current_link = nil
    begin
      page.search("//script[@src]").each do |link|
        current_link = link
        yield new_link(uri, link["src"])
      end if page.respond_to?(:search)
    rescue
      log_link_error($!, uri, current_link)
    end
  end

  def log_link_error(exception, uri, current_link=nil)
    data = current_link.if_not_nil do |link|
      link.respond_to?(:href) ? [link.text, link.href] : link.inspect
    end

    self.results[:bad_urls] << [uri.to_s, exception.message, data].compact
    self.save!
  end

  protected
  def presence_of_root
    errors.add_to_base("root argument missing") if self.args[:root].blank?
  end

  def new_link(base_uri, target)
    begin
      base_uri.merge(target.to_s)
    rescue URI::InvalidURIError
      # Try again, but encode the target first
      base_uri.merge(target.gsub(/\s/, "+").gsub(",", "%2C").gsub("|","%7C"))
    end
  end

  def same_host?(root, tester)
    uri0 = root.normalize
    uri1 = tester.normalize

    case
    when uri0.absolute? && !uri1.absolute?
      true # uri1 is not absolute, hence it refers to the same domain
    when uri0.scheme != uri1.scheme
      false # Difference scheme: ftp vs http, http vs mailto
    else
      # Check only the top-level domain:
      #  www.mydomain.com == mydomain.com
      #  jim.mydomain.com == john.mydomain.com
      #  mydomain.com == mydomain.com
      uri0_host = uri0.host.split(".").map(&:strip).reject{|e| e =~ /\Awww\Z/i}
      uri1_host = uri1.host.split(".").map(&:strip).reject{|e| e =~ /\Awww\Z/i}
      uri0_host.join(".") == uri1_host.join(".")
    end
  end
end
