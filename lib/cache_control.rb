#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module CacheControl
  def self.included(base)
    if %w(validates_numericality_of validates_inclusion_of).all? {|m| base.respond_to?(m)} then
      base.validates_numericality_of :cache_timeout_in_seconds, :allow_nil => true
      base.validates_inclusion_of :cache_timeout_in_seconds, :within => (0 .. 1.year), :message => "must be from 0 seconds to 1 year", :allow_nil => true
      base.validates_inclusion_of :cache_control_directive, :in => %w(public private no-cache), :allow_nil => true
    end
  end

  # Returns the cache control headers for self
  def cache_control_headers
    params = Hash.new
    params[:updated_at] = self.updated_at if self.respond_to?(:updated_at)
    params[:cache_control_directive] = self.cache_control_directive
    params[:cache_timeout_in_seconds] = self.cache_timeout_in_seconds

    CacheControl.cache_control_headers(params)
  end
  
  def allow_cache?
    self.cache_control_directive != "no-cache"
  end

  # Returns a Hash of headers suitable for HTTP which control caching.
  def self.cache_control_headers(params={})
    updated_at = params[:updated_at]
    cache_control_directive = params[:cache_control_directive]
    cache_timeout_in_seconds = params[:cache_timeout_in_seconds]

    returning(Hash.new) do |headers|
      headers["Cache-Control"] = Array.new

      headers["Cache-Control"] << cache_control_directive

      case cache_control_directive
      when "public", "private"
        if cache_timeout_in_seconds then
          headers["Cache-Control"] << "max-age=#{cache_timeout_in_seconds}" 
          headers["Expires"] = cache_timeout_in_seconds.from_now.to_http_header_format
          headers["Pragma"] = "no-cache" if cache_timeout_in_seconds.zero?
        end
      when "no-cache"
        headers["Cache-Control"] << "no-store"
        headers["Cache-Control"] << "max-age=0" 
        headers["Expires"] = 10.years.ago.to_http_header_format
        headers["Pragma"] = "no-cache"
      end

      headers["Cache-Control"] << "must-revalidate"
      headers["Cache-Control"] = headers["Cache-Control"].compact.uniq.join(", ")
    end.reject {|k,v| v.blank?}
  end
end
