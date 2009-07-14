class AddTwitterUsernameColumnToParties < ActiveRecord::Migration
  def self.up
    add_column :parties, :twitter_username, :string
  end

  def self.down
    remove_column :parties, :twitter_username
  end
end
