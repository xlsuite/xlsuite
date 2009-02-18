class SetValueOfOrderPaidInFullAt < ActiveRecord::Migration
  def self.up
    Order.all.map(&:save)
  end

  def self.down
  end
end
