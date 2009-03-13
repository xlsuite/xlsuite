#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module Extensions
  module Payables
    def completed
      find(:all, :joins => "INNER JOIN payments ON payables.payment_id = payments.id AND payments.state='paid'", :conditions => {:voided_at => nil})
    end

    def total_completed(currency=Money.default_currency)
      completed.map(&:amount).compact.sum(Money.zero(currency))
    end
    
    def latest
      find(:first, :order => "created_at DESC, id DESC")
    end
  end
end
