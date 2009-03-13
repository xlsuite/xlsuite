#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RenewSubscriptionFuture < Future
  def run
    Subscription.all(:conditions => ["next_renewal_at <= ?", Time.now.utc], :limit => 1000).each do |subscription|
      MethodCallbackFuture.create!(:model => subscription, :method => "pay!", :system => true)
    end
    self.complete!
  end
end
