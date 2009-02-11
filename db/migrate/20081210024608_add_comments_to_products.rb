class AddCommentsToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :average_rating, :decimal, :precision => 5, :scale => 3, :default => 0, :null => false
    add_column :products, :hide_comments, :boolean, :default => false
    add_column :products, :deactivate_commenting_on, :date
    add_column :products, :comment_approval_method, :string, :default => "Moderated"
  end

  def self.down
    remove_column :products, :average_rating
    remove_column :products, :hide_comments
    remove_column :products, :deactivate_commenting_on
    remove_column :products, :comment_approval_method
  end
end
