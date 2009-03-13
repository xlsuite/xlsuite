#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CopyAccountConfigurationsFuture < Future
  def run
    Account.transaction do
      self.account.copy_configurations
    end
    self.complete!
  end

  def owner_required?
    false
  end
end
