#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FeedsUpdator < Future
  def run
    Feed.find(:all, :conditions => ["refreshed_at <= ?", 31.hours.ago],
              :order => "refreshed_at", :limit => 10).each do |feed|
      MethodCallbackFuture.create!(:system => true, :model => feed, :method => :refresh, :priority => 200)
    end

    self.complete!
  end
end
