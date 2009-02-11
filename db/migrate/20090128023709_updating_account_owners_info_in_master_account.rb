class UpdatingAccountOwnersInfoInMasterAccount < ActiveRecord::Migration
  def self.up
    Account.all.each do |account|
      MethodCallbackFuture.create!(:account => account, :model => account, :method => "update_account_owner_info_in_master_account")
    end
  end

  def self.down
    MethodCallbackFuture.delete_all(:conditions => "args LIKE '%update_account_owner_info_in_master_account%'")
  end
end
