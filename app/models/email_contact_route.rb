#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailContactRoute < ContactRoute
  acts_as_reportable :columns => %w(email_address)

  ValidAddressRegexp = %r{[A-Z0-9._%-]+@(?:localhost|[A-Z0-9.-]+\.[A-Z]{2,})}i.freeze

  validates_presence_of :email_address
  validates_uniqueness_of :email_address, :scope => [:account_id, :routable_type], :if => Proc.new {|email| email.routable_type == "Party"}
  validates_format_of :email_address, :with => ValidAddressRegexp, :allow_nil => true

  attr_writer :fullname

  def fullname
    return @fullname unless @fullname.blank?
    if self.routable && self.routable.respond_to?(:name) && self.routable.name && self.routable.name.respond_to?(:to_forward_s) then
      self.routable.name.to_forward_s
    else
      nil
    end
  end

  def to_liquid
    EmailDrop.new(self)
  end

  def to_formatted_s(should_use_parens = false)
    buffer = []
    buffer << %Q("#{self.fullname}") unless self.fullname.blank?

    if should_use_parens
      buffer << "(#{self.email_address})"
    else
      buffer << "<#{self.email_address}>"
    end
    
    buffer.join(" ")
  end

  def to_s
    returning("#{self.fullname} <#{self.email_address}>".strip) do |str|
      if str[0,1] == "<" then
        str.sub!("<", "")
        str.sub!(">", "")
      end
    end
  end

  def to_alt_formatted_s
    return "#{self.fullname} (#{self.email_address})"
  end
  
  def choices
    super %w(Personal Work)
  end

  def address
    self.email_address
  end

  def address=(value)
    self.email_address = value
  end

  def blank?
    self.email_address.blank?
  end

  def to_xml(options={})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.tag! "email-address", :id => self.dom_id do
      xml.name self.name
      xml.address self.address
    end
  end

  class << self
    def find_by_address(address)
      find_by_email_address(address)
    end
    
    def find_by_address_and_routable_type(address, routable_type)
      find_by_email_address_and_routable_type(address, routable_type)
    end

    def decode_name_and_address(email_plus_name)
      address, name = email_plus_name.slice(/<\s*(.+)\s*>/, 1), ""
      if address.blank? then
        address = email_plus_name.slice(/\A\s*(.+@.+\..+)\s*\Z/, 1)
      else
        name = email_plus_name.slice(/"\s*(.+)\s*"/, 1) || email_plus_name.slice(/\A(.*)(?=<)/, 1)
      end

      [name.strip, address.strip]
    end

    def valid_address?(address)
      address =~ ValidAddressRegexp
    end
  end
end
