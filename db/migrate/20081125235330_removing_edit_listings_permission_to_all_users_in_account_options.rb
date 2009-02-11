class RemovingEditListingsPermissionToAllUsersInAccountOptions < ActiveRecord::Migration
  def self.up
    Account.all.each do |account|
      opt_attr = account.read_attribute(:options)
      opt_attr.delete(:edit_listings_permission_to_all_users)
      account.options = opt_attr
      account.save
    end
  end

  def self.down
  end
end
