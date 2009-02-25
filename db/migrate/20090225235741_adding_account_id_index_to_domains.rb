class AddingAccountIdIndexToDomains < ActiveRecord::Migration
  def self.up
    add_index :domains, [:account_id], :name => "by_account"
  end

  def self.down
    remove_index :domains, :name => "by_account"
  end
end
