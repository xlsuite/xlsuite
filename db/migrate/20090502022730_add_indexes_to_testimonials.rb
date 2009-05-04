class AddIndexesToTestimonials < ActiveRecord::Migration
  def self.up
    add_index :testimonials, :account_id, :name => "by_account"
  end

  def self.down
    remove_index :testimonials, :name => "by_account"
  end
end
