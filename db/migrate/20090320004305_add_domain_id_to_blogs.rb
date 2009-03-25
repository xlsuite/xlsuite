class AddDomainIdToBlogs < ActiveRecord::Migration
  def self.up
    add_column :blogs, :domain_id, :integer
  end

  def self.down
    remove_column :blogs, :domain_id
  end
end
