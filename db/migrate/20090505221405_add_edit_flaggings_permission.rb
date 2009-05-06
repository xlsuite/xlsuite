class AddEditFlaggingsPermission < ActiveRecord::Migration
  def self.up
    permission = Permission.find_or_create_by_name("edit_flaggings")
    accounts = Account.all.select(&:owner)
    MethodCallbackFuture.create!(:models => accounts, :method => :grant_all_permissions_to_owner, :system => true)
  end

  def self.down
    Permission.find_by_name("edit_flaggings").destroy
    accounts = Account.all.select(&:owner)
    MethodCallbackFuture.create!(:models => accounts, :method => :grant_all_permissions_to_owner, :system => true)
  end
end
