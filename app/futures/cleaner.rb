#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Cleaner < Future
  def run
    status!(:initializing, 0)
    cutoff_at = 24.hours.ago
    Future.delete_all("status = 'completed' AND ended_at < '#{cutoff_at.to_s(:db)}' AND `interval` IS NULL")
    self.complete!
  end
end
