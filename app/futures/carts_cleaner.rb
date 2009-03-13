#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CartsCleaner < Future
  def run
    Cart.find(:all, :conditions => ["updated_at <= ?", 1.hours.ago],
              :order => "updated_at", :limit => 20).each do |cart|
      cart.destroy
    end
    self.complete!
  end
end
