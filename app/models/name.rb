#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Name
  include Comparator
  extend Comparator
  include Comparable
  include JavascriptEscaper

  attr_accessor :first, :last, :middle

  def initialize(last=nil, first=nil, middle=nil)
    @last, @first, @middle = last, first, middle
  end

  def <=>(other)
    x = Name::nil_safe_case_insensitive_compare(self.last, other.last)
    return x unless 0 == x

    x = Name::nil_safe_case_insensitive_compare(self.first, other.first)
    return x unless 0 == x

    Name::nil_safe_case_insensitive_compare(self.middle, other.middle)
  end

  def ==(other)
    self.last == other.last && self.first == other.first && self.middle == other.middle
  end

  def to_backward_s
    right = [self.first, self.middle].reject(&:blank?).join(' ')
    [self.last, right].reject(&:blank?).join(', ')
  end

  def to_forward_s
    [self.first, self.middle, self.last].reject(&:blank?).join(' ')
  end

  alias_method :to_s, :to_forward_s
  alias_method :to_liquid, :to_forward_s

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.name do
      xml.first self.first
      xml.middle self.middle
      xml.last self.last
    end
  end
  
  def to_json
    %Q!'name':{'first':'#{e(self.first)}',\
      'middle':'#{e(self.middle)}',\
      'last':'#{e(self.last)}'}!
  end

  def self.parse(name)
    name_array = name.split(/\s*,\s*/)
    if name_array.length > 1
      last = name_array.shift
      name_array = name_array.join(" ").split(/\s+/)
      first = name_array.shift
      middle = name_array.join(" ") unless name_array.blank?
    else
      name_array = name.split(/\s*,\s*|\s+/)
      first = name_array.shift
      last = name_array.pop
      middle = name_array.join(" ") unless name_array.blank?
    end
    return self.new(last, first, middle)
  end
end
