#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ListingsDrop < Liquid::Drop
  attr_reader :account
  
  def initialize(account)
    @account = account
  end
  
  def max_price
    MoneyDrop.new(@account.listings.maximum(:price_cents).to_money)
  end
  
  def min_price
    MoneyDrop.new(@account.listings.minimum(:price_cents).to_money)
  end
end
