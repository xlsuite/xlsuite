#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PhoneDrop < Liquid::Drop
  attr_reader :phone
  delegate :name, :to => :phone

  def initialize(phone)
    @phone = phone
  end

  def number
    phone.formatted_number
  end

  def extension
    phone.formatted_extension
  end
end
