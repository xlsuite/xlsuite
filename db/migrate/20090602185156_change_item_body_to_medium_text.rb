class ChangeItemBodyToMediumText < ActiveRecord::Migration
  def self.up
    change_column :items, :body, :mediumtext
    change_column :items, :cached_parsed_body, :mediumblob
  end

  def self.down
    change_column :items, :body, :text
    change_column :items, :cached_parsed_body, :blob
  end
end
