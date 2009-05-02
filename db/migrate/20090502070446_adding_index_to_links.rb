class AddingIndexToLinks < ActiveRecord::Migration
  def self.up
    add_index :links, [:account_id, :title, :approved, :active_at], :name => "by_account_title_approved_active_at"
  end

  def self.down
    remove_index :links, :name => "by_account_title_approved_active_at"
  end
end
