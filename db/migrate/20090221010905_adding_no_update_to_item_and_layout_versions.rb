class AddingNoUpdateToItemAndLayoutVersions < ActiveRecord::Migration
  def self.up
    add_column :layout_revisions, :no_update, :boolean, :default => false
    add_column :item_revisions, :no_update, :boolean, :default => false
  end

  def self.down
    remove_column :layout_revisions, :no_update
    remove_column :item_revisions, :no_update
  end
  
  class ItemRevision < ActiveRecord::Base;end
  class LayoutRevision < ActiveRecord::Base;end
end
