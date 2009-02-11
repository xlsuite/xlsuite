class CreateDefaultAccountOwnersGroup < ActiveRecord::Migration
  def self.up
    master_account = Account.find_by_master(true)
    Group.create(:account => master_account, :label => "XLsuite_trial", :name => "XLsuite_trial")
  end

  def self.down
    master_account = Account.find_by_master(true)
    Group.find(:first, :conditions => {:label => "XLsuite_trial", :account_id => master_account.id})
  end
end
