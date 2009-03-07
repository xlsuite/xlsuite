class AddDomainIdToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :domain_id, :integer
  end

  def self.down
    remove_column :comments, :domain_id
  end
end
