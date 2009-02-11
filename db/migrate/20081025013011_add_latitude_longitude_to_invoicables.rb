class AddLatitudeLongitudeToInvoicables < ActiveRecord::Migration
  def self.up
    %w(estimates orders invoices).each do |table_name|
      add_column table_name, :latitude, :float
      add_column table_name, :longitude, :float
    end
  end

  def self.down
    %w(estimates orders invoices).reverse.each do |table_name|
      remove_column table_name, :longitude
      remove_column table_name, :latitude
    end
  end
end
