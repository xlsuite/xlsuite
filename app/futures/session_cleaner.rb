#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SessionCleaner < Future
  def run
    status!(:initializing, 0)
    cutoff_time = Time.now.utc - self.interval
    cutoff_time = self.connection.quote(cutoff_time)
    self.transaction do
      self.connection.execute "DELETE FROM sessions WHERE updated_at < #{cutoff_time}"
    end
    self.complete!
  end
end
