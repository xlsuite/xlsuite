#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ExpiredConfirmationAccountsCleanerFuture < Future
  def run
    accounts = Account.all(:conditions => ["confirmation_token_expires_at <= ?", Time.now], :limit => 10)
    MethodCallbackFuture.create!(:models => accounts, :method => "destroy", :system => true) unless accounts.empty?
    self.complete!
  end
end
