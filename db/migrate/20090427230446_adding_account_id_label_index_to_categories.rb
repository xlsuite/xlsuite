class AddingAccountIdLabelIndexToCategories < ActiveRecord::Migration
  def self.up
    add_index :categories, [:account_id, :label], :name => "by_account_and_label"
  end

  def self.down
    remove_index :categories, :name => "by_account_and_label"
  end
end
