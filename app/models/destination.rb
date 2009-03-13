#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Destination < ActiveRecord::Base
  acts_as_fulltext %w(country state cost)
  
  belongs_to :account
  acts_as_money :cost
  
  validates_presence_of :account_id, :cost, :country
  validates_uniqueness_of :state, :scope => ["country", "account_id"], :message => "has already been taken for this country"
  
  before_save :set_state_to_blank_if_nil
  
  class << self
    def shipping_cost_for_country_and_state(country="", state="", currency=Money.default_currency)
      country ||= ""
      state ||= ""
      country.strip!
      state.strip!
      
      destination = self.find_by_country_and_state(country, state)
      destination = self.find_by_country_and_state(country, "") unless destination
      destination = self.find_by_country_and_state("All Others", "") unless destination
      
      destination ? destination.cost : Money.zero(currency)
    end
  end
  
  protected
  def set_state_to_blank_if_nil
    if self.state == nil
      self.state = ""
    end
  end
  
end
