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
  
  def before_method(method)
    if method.to_s =~ /^latitude_(plus|minus)_(.*)/i
      operator = $1
      number = $2
      return self.latitude + number.gsub("_", ".").to_f if operator =~ /plus/
      return self.latitude - number.gsub("_", ".").to_f if operator =~ /minus/
    end
    if method.to_s =~ /^longitude_(plus|minus)_(.*)/i
      operator = $1
      number = $2
      return self.longitude + number.gsub("_", ".").to_f if operator =~ /plus/
      return self.longitude - number.gsub("_", ".").to_f if operator =~ /minus/
    end
    nil
  end
end
