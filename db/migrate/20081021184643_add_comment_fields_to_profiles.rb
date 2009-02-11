class AddCommentFieldsToProfiles < ActiveRecord::Migration
  def self.up
    add_column :profiles, :average_rating, :decimal, :precision => 5, :scale => 3, :default => 0, :null => false
    add_column :profiles, :hide_comments, :boolean, :default => false
    add_column :profiles, :deactivate_commenting_on, :date
  end

  def self.down
    remove_column :profiles, :average_rating
    remove_column :profiles, :hide_comments
    remove_column :profiles, :deactivate_commenting_on
  end
end
