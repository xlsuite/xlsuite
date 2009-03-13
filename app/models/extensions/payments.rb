#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module Extensions
  module Payments
    def completed
      find(:all, :conditions => {:state => "paid"})
    end

    def total_completed(currency=Money.default_currency)
      completed.map(&:amount).compact.sum(Money.zero(currency))
    end
  end
end
