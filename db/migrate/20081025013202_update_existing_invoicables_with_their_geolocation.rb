class UpdateExistingInvoicablesWithTheirGeolocation < ActiveRecord::Migration
  def self.up
    %w(estimates orders invoices).each do |table_name|
      class_name = table_name.classify
      execute "UPDATE #{table_name} t INNER JOIN contact_routes cr ON cr.routable_type = '#{class_name}' AND cr.routable_id = t.id SET t.latitude = cr.latitude, t.longitude = cr.longitude"
    end
  end

  def self.down
  end
end
