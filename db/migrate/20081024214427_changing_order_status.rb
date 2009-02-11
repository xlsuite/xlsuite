class ChangingOrderStatus < ActiveRecord::Migration
  def self.up
    Order.update_all(["status=?", "New"], ["status=?", "pending"])
    Order.update_all(["status=?", "Pending"], ["status=?", "Unfulfilled"])
    Order.update_all(["status=?", "Completed"], ["status=?", "Fulfilled"])
  end

  def self.down
    Order.update_all(["status=?", "Fulfilled"], ["status=?", "Completed"])
    Order.update_all(["status=?", "Unfulfilled"], ["status=?", "Pending"])
    Order.update_all(["status=?", "pending"], ["status=?", "New"])
  end
  
  class Order < ActiveRecord::Base; end
end
