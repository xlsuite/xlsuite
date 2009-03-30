#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ExpiredAccountsCleanerFuture < Future
  def run
    result = [] 
    Account.all(:conditions => ["expires_at <= ?", EXPIRED_ACCOUNT_DEADLINE_IN_MONTH.months.ago]).each do |account|
      next if account.domains.count > 1
      next if account.domains.first.name =~ /template\./i
      next if account.account_template_as_trunk
      result << account
      break if result.size > 10
    end
    MethodCallbackFuture.create!(:system => true, :models => result, :method => "destroy") unless result.empty?
    self.complete!
  end
end
