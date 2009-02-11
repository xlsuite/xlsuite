class InitializeVersionColumnInItems < ActiveRecord::Migration
  def self.up
    Item.update_all("version=1")
    Item.find(:all).each do |i|
      attrs = i.attributes
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.merge!(:item_id => i.id, :version => 1, :versioned_type => attrs.delete("type"))
      ItemVersion.create!(attrs)
    end
  end

  def self.down
    Item.update_all("version=NULL")
    ItemVersion.delete_all
  end
  
  class Item < ActiveRecord::Base; end
  class ItemVersion < ActiveRecord::Base; end
end
