#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class LinkContactRoute < ContactRoute
  acts_as_reportable :columns => %w(url)

  validates_presence_of :url
  validates_length_of :url, :within => (1 .. 500)

  def formatted_url
    value = self.url
    return nil if value.blank? 
    value["://"] ? value : "http://#{value}"
  end

  def choices
    super %w(Company Blog Personal)
  end

  def to_s
    formatted_url
  end
  
  def main_identifier
    self.to_s
  end

  def to_liquid
    LinkContactRouteDrop.new(self)
  end

  def to_xml(options={})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.link(:id => self.dom_id) do
      xml.name self.name
      xml.url self.formatted_url
    end
  end
end
