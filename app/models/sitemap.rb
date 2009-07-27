class Sitemap < ActiveRecord::Base
  acts_as_list :scope => "domain_id"
  belongs_to :domain
  validates_presence_of :text, :domain_id
  MAX_URL = 49000
  
  def self.create_sitemaps_of!(domain)
    sitemap = nil
    count = SitemapLink.count(:id, :conditions => {:domain_id => domain.id})
    Sitemap.all(:select => "id, position", :conditions => {:domain_id => domain.id}).map(&:destroy)
    rep = (count.to_f / MAX_URL).ceil
    (1..rep).each do |i|
      links = SitemapLink.all(:conditions => {:domain_id => domain.id}, :offset => (i-1)*MAX_URL, :limit => MAX_URL)
      sitemap = Sitemap.new(:domain => domain)
      sitemap.append_open_tag!
      links.each do |link|
        sitemap.append_link!(link)
      end
      sitemap.append_closing_tag!
      sitemap.save!
    end
    true
  end
  
  def append_open_tag!
    self.text = "" if self.text.blank?
    self.text << %Q`<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">`
    true
  end
  
  def append_closing_tag!
    self.text << %Q`</urlset>`
    true
  end
  
  def append_link!(sitemap_link)
    t_link = self.class.entity_escaping(sitemap_link.url)
    freq = %w(daily weekly monthly yearly)
    level = sitemap_link.url.split("/").reject(&:blank?).size - 2
    frequency = freq[level]
    frequency = freq.last if frequency.blank?
    self.text << %Q`<url><loc>#{t_link}</loc><lastmod>#{sitemap_link.updated_at.strftime("%Y-%m-%d")}</lastmod><changefreq>#{frequency}</changefreq><priority>0.5</priority></url>\n`
    true
  end
  
  def self.entity_escaping(input)
    input.gsub("&", "&amp;").gsub("'", "&apos;").gsub('"', "&quot;").gsub(">", "&gt;").gsub("<", "&lt")
  end
end
