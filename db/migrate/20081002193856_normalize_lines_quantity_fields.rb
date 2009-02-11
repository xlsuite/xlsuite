class NormalizeLinesQuantityFields < ActiveRecord::Migration
  def self.up
    change_column :cart_lines, :quantity, :decimal, :precision => 12, :scale => 4, :null => true, :default => nil
    change_column :estimate_lines, :quantity, :decimal, :precision => 12, :scale => 4, :null => true, :default => nil
    change_column :order_lines, :quantity, :decimal, :precision => 12, :scale => 4, :null => true, :default => nil
    change_column :invoice_lines, :quantity, :decimal, :precision => 12, :scale => 4, :null => true, :default => nil
  end

  def self.down
  end
end
