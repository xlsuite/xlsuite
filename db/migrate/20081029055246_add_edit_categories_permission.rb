class AddEditCategoriesPermission < ActiveRecord::Migration
  def self.up
    permission = Permission.find_or_create_by_name("edit_categories")
    Account.all.each do |account|
      next unless account.owner
      MethodCallbackFuture.create!(:model => account, :method => :grant_all_permissions_to_owner, :system => true)
      MethodCallbackFuture.create!(:model => account.owner, :method => :generate_effective_permissions, :account => account)
    end
  end

  def self.down
    Permission.find_by_name("edit_categories").destroy
    Account.all.each do |account|
      next unless account.owner
      MethodCallbackFuture.create!(:model => account, :method => :grant_all_permissions_to_owner, :system => true)
      MethodCallbackFuture.create!(:model => account.owner, :method => :generate_effective_permissions, :account => account)
    end
  end
end
