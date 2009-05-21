#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Snippet < Item
  acts_as_fulltext %w(title body domain_patterns behavior)
  
  attr_accessor :ignore_warnings
  attr_protected :ignore_warnings
  
  before_save :check_for_recursion
  
  def to_liquid
    SnippetDrop.new(self)
  end
  
  class << self
    def find_by_domain_and_title(domain, title)
      snippets = find(:all, :conditions => ["title = ? AND published_at <= ?", title, Time.now.utc])
      snippets.blank? ? nil : snippets.best_match_for_domain(domain)
    end

    def find_by_domain_and_title!(domain, title)
      returning find_by_domain_and_title(domain, title) do |snippet|
        raise ActiveRecord::RecordNotFound unless snippet
      end
    end
  end

  def self.to_new_from_item_version(item_version)
    attrs = item_version.attributes
    %w(id item_id versioned_type cached_parsed_title cached_parsed_body).each do |attr_name|
      attrs.delete(attr_name)
    end
    snippet = self.new(attrs)
    snippet
  end
  
  protected
  def check_for_recursion
    regexp_string = %Q`\\{%\\s*render_snippet[^%]*title:\\s*["']?` + self.title + %Q`["']?\\s*%\\}`
    if self.body =~ Regexp.new(regexp_string, true)
      self.warnings.add_to_base("This snippet refers to itself")
      return false unless self.ignore_warnings
    end
    true
  end
end
