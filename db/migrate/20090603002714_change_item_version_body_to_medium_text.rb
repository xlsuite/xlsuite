class ChangeItemVersionBodyToMediumText < ActiveRecord::Migration
  def self.up
    change_column :item_versions, :body, :mediumtext
    change_column :item_versions, :cached_parsed_body, :mediumblob
  end

  def self.down
    change_column :item_versions, :body, :text
    change_column :item_versions, :cached_parsed_body, :blob
  end
end
