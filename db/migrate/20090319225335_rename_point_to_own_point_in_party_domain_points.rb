class RenamePointToOwnPointInPartyDomainPoints < ActiveRecord::Migration
  def self.up
    rename_column :party_domain_points, :point, :own_point
  end

  def self.down
    rename_column :party_domain_points, :own_point, :point
  end
end
