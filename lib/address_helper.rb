#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'comparator'

module AddressHelper
  include Comparator
  extend Comparator

  def format
    lines = case self.country
    when 'USA'
      [self.line1, self.line2, "#{self.city} #{self.state}  #{self.zip}", self.country]

    when 'CA'
      [self.line1, self.line2, "#{self.city} #{self.state}  #{self.zip}"]

    else
      [self.line1, self.line2, "#{self.city} #{self.state}", self.zip, self.country]
    end

    lines.map {|l| (l.blank? or l.strip.blank?) ? nil : l.strip}.compact
  end

  def clean_address
    self.line1 = self.line1.upcase.gsub(/\s{2,}/, ' ').titleize   unless self.line1.blank?
    self.line2 = self.line2.upcase.gsub(/\s{2,}/, ' ').titleize   unless self.line2.blank?
    self.city = self.city.upcase.gsub(/\s{2,}/, ' ').titleize     unless self.city.blank?
    self.state = self.state.upcase.gsub(/\s/, '').upcase          unless self.state.blank?
    self.zip = self.zip.upcase.gsub(/\s/, '').upcase              unless self.zip.blank?
    self.country = self.country.upcase.gsub(/\s/, '').upcase      unless self.country.blank?
    return if zip.blank?

    case self.country
    when 'CA'
      self.zip = "#{self.zip[0...3]} #{self.zip[3..-1]}"

    when 'USA'
      if self.zip.length > 5 then
        self.zip = "#{self.zip[0...5]}-#{self.zip[5..-1]}"
      end
    end
  end

  def ==(other)
    0 == nil_safe_case_insensitive_compare(self.line1, other.line1) &&
    0 == nil_safe_case_insensitive_compare(self.line2, other.line2) &&
    0 == nil_safe_case_insensitive_compare(self.city, other.city) &&
    0 == nil_safe_case_insensitive_compare(self.state, other.state) &&
    0 == nil_safe_case_insensitive_compare(self.zip, other.zip) &&
    0 == nil_safe_case_insensitive_compare(self.country, other.country)
  end

  def to_s
    format.join(', ')
  end
end
