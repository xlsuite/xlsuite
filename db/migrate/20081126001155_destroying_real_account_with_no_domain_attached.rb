class DestroyingRealAccountWithNoDomainAttached < ActiveRecord::Migration
  def self.up
    Account.all(:conditions => "party_id IS NOT NULL AND signup_account_id IS NOT NULL").each do |account|
      if account.domains.count < 1
        account.destroy
      end
    end
  end

  def self.down
  end
end
