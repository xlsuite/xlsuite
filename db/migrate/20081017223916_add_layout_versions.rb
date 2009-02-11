class AddLayoutVersions < ActiveRecord::Migration
  def self.up
    Layout.create_versioned_table
  end

  def self.down
    Layout.drop_versioned_table
    remove_column :layouts, :version
  end
  
  class Layout < ActiveRecord::Base
    acts_as_versioned
  end
end
