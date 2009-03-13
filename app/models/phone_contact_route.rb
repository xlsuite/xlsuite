#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PhoneContactRoute < ContactRoute
  acts_as_reportable :columns => %w(number extension)

  validates_presence_of :number

  def plain_number
    self.number.gsub(/\D/, "")
  end

  def formatted_number
    return nil if self.number.blank?
    
    #don't format number if length is greater than 11; we don't know which digits are area code etc..
    return self.number if self.plain_number.length > 11
    
    case self.plain_number
    when /^1?([1-9]\d{2})(\d{3})(\d{4})$/, /^([1-9]\d{2})(\d{3})(\d{4})$/
      "+1 (#{$1}) #{$2}-#{$3}"
    when /^(\d{3})(\d{4})$/
      "#{$1}-#{$2}"
    else
      self.number
    end 
  end

  def formatted_extension
    return nil if self.extension.blank?
    "x#{self.extension.gsub(/[^\d\s]/, '')}"
  end
  
  def formatted_number_with_extension
    ((self.formatted_number || "") + " " + (self.formatted_extension || "")).strip
  end

  def choices
    super %w(Home Office Cell Mobile Pager Fax Day Night)
  end

  def to_liquid
    PhoneDrop.new(self)
  end

  def to_s
    buffer = []
    buffer << "#{self.name}:" unless self.name.blank? || self.name.empty?
    buffer << self.formatted_number unless self.number.blank?
    buffer << "x#{self.extension}" unless self.extension.blank?
    buffer.join(" ")
  end

  def area_code
    return nil if self.number.blank?
    $1 if self.number.gsub(/\D/, '') =~ /^1?(\d{3})\d{7}/
  end

  def to_xml(options={})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.phone(:id => self.dom_id) do
      xml.name self.name
      xml.number self.formatted_number
      xml.extension self.formatted_extension
    end
  end
  
  def to_json
    %Q!{'id':'#{self.dom_id}', 'name':'#{self.name}', 'number':'#{self.formatted_number}', 'extension':'#{self.formatted_extension}' }!
  end

  class << self
    def find_by_similar_number(number)
      return nil if number.blank?
      self.find(:first, :conditions => ["number LIKE ?", "%" << number.gsub(/\D/, "").split(//).join("%") << "%"])
    end
  end
end
