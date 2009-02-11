class AddHideCommentsAndDeactivateCommentsToListings < ActiveRecord::Migration
  def self.up
    add_column :listings, :hide_comments, :boolean, :default => false
    add_column :listings, :deactivate_commenting_on, :date
  end

  def self.down
    remove_column :listings, :hide_comments
    remove_column :listings, :deactivate_commenting_on
  end
end
