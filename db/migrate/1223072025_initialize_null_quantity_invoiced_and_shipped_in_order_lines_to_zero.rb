class InitializeNullQuantityInvoicedAndShippedInOrderLinesToZero < ActiveRecord::Migration
  def self.up
    OrderLine.update_all(["quantity_invoiced=?", 0], ["quantity_invoiced IS NULL"])
    OrderLine.update_all(["quantity_shipped=?", 0], ["quantity_shipped IS NULL"])
  end

  def self.down
    OrderLine.update_all("quantity_invoiced=NULL")
    OrderLine.update_all("quantity_shipped=NULL")
  end
end
