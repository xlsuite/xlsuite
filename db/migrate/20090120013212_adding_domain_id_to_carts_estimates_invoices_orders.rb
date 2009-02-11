class AddingDomainIdToCartsEstimatesInvoicesOrders < ActiveRecord::Migration
  def self.up
    add_column :carts, :domain_id, :integer
    add_column :estimates, :domain_id, :integer
    add_column :invoices, :domain_id, :integer
    add_column :orders, :domain_id, :integer
  end

  def self.down
    remove_column :carts, :domain_id
    remove_column :estimates, :domain_id
    remove_column :invoices, :domain_id
    remove_column :orders, :domain_id
  end
end
