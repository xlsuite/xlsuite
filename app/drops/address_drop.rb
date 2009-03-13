#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AddressDrop < Liquid::Drop
  delegate :line1, :line2, :line3, :city, :state, :country, :zip, :full_country, :full_state, 
           :longitude, :latitude, :to => :address
  attr_reader :address

  def initialize(address)
    @address = address
  end

  def province
    self.state
  end

  def full_province
    self.full_state
  end

  def postal_code
    self.zip
  end
end
