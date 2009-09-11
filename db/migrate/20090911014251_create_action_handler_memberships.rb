class CreateActionHandlerMemberships < ActiveRecord::Migration
  def self.up
    create_table :action_handler_memberships do |t|
      t.column :action_handler_id, :integer
      t.column :party_id, :integer
      t.column :domain_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :action_handler_memberships
  end
end
