class ChangeLayoutAuthorIdToCreatorId < ActiveRecord::Migration
  def self.up
    rename_column :layouts, :author_id, :creator_id
    rename_column :layout_versions, :author_id, :creator_id
  end

  def self.down
    rename_column :layouts, :creator_id, :author_id
    rename_column :layout_versions, :creator_id, :author_id
  end
end
