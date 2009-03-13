#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class DomainCleanupFuture < Future
  def run
    status!(:initializing, 0)
    Domain.find(:all, :conditions => ["activated_at IS NULL AND created_at < ?", 1.hour.ago]).map(&:destroy)
    self.complete!
  end
end
