class CreateContactRequestRecipientsTable < ActiveRecord::Migration
  def self.up
    create_table(:contact_request_recipients, :id => false) do |t|
      t.column :party_id, :integer
      t.column :contact_request_id, :integer
    end
  end

  def self.down
    drop_table :contact_request_recipients
  end
end
