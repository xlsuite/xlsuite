class AddOrderPaidInFullAtColumn < ActiveRecord::Migration
  def self.up
    add_column :orders, :paid_in_full_at, :datetime
  end

  def self.down
    remove_column :orders, :paid_in_full_at
  end
end
