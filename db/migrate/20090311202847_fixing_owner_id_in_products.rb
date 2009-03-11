class FixingOwnerIdInProducts < ActiveRecord::Migration
  def self.up
    party = nil
    Product.all(:conditions => "owner_id IS NOT NULL").each do |product|
      party = product.owner
      unless party
        product.update_attribute(:owner_id, nil)
        next
      end
      party = Party.find(:first, :conditions => {:account_id => product.account_id, :id => product.owner_id})
      unless party
        product.update_attribute(:owner_id, nil)
      end
    end
  end

  def self.down
  end
end
