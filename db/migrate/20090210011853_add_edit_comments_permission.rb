class AddEditCommentsPermission < ActiveRecord::Migration
  def self.up
    permission = Permission.find_or_create_by_name("edit_comments")
    Account.all.each do |account|
      next unless account.owner
      MethodCallbackFuture.create!(:model => account, :method => :grant_all_permissions_to_owner, :system => true)
    end
  end

  def self.down
    Permission.find_by_name("edit_comments").destroy
    Account.all.each do |account|
      next unless account.owner
      MethodCallbackFuture.create!(:model => account, :method => :grant_all_permissions_to_owner, :system => true)
    end
  end
end
