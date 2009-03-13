#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "uri"

class Redirect < Page
  validate :not_a_self_redirect
  before_validation :set_http_code
  
  TYPES_FOR_SELECT = [["Moved Permanently", 301], ["Temporary Redirect", 307]].freeze
  DEFAULT_HTTP_CODE = 307

  def redirect?
    true
  end
  
  def http_code_status=(status_string)
    self.http_code = TYPES_FOR_SELECT.find {|e| e[0] == status_string}.last
  end
  
  def http_code_status
    TYPES_FOR_SELECT.find {|e| e[1] == self.http_code}.first
  end
  
  def title_required?
    false
  end

  def layout_required?
    false
  end

  def target
    self.body
  end

  def target=(value)
    self.body = value
  end

  def render_on_domain(domain, options)
    redirect_url = "http"
    redirect_url << "s" if require_ssl?
    redirect_url << "://"
    if self.target.first == "/"
      redirect_url << domain.name
      redirect_url << ":#{options[:port]}" if options.has_key?(:port)
    end
    
    if self.target =~ /https?:\/\//i
      redirect_url = self.target
    else
      redirect_url << self.target
    end
    
    [:redirect, redirect_url, {:status => self.http_code}]
  end

  protected
  def not_a_self_redirect
    self.errors.add_to_base("Redirects from one page to the same page are invalid") if URI.parse("/#{self.fullslug}") == URI.parse(self.target)
  end
  
  def set_http_code
    self.http_code = 301 if self.http_code < 300 || self.http_code > 307
  end
end
