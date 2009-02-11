class AddItemVersions < ActiveRecord::Migration
  def self.up
    Item.create_versioned_table
  end

  def self.down
    Item.drop_versioned_table
    remove_column :items, :version
  end
  
  class Item < ActiveRecord::Base
    acts_as_versioned
  end
end
