class AddGroupIdsColumnToProfileRequests < ActiveRecord::Migration
  def self.up
    add_column :profile_requests, :group_ids, :string
  end

  def self.down
    remove_column :profile_requests, :group_ids
  end
end
