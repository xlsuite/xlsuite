class Set307HttpCodeOnAllRedirects < ActiveRecord::Migration
  def self.up
    Item.update_all("http_code=307", "type='Redirect'")
  end

  def self.down
    Item.update_all("http_code=200", "type='Redirect'")
  end
  
  class Item < ActiveRecord::Base;end
end
