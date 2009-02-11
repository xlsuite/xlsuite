class SetAllRedirectsToBePermanent < ActiveRecord::Migration
  def self.up
    Item.update_all("http_code=301", "type='Redirect' AND http_code=307")
  end

  def self.down
  end
  
  class Item < ActiveRecord::Base; end
end
