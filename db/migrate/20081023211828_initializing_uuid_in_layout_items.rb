class InitializingUuidInLayoutItems < ActiveRecord::Migration
  def self.up
    execute "UPDATE layout_versions lv INNER JOIN layouts l ON l.id = lv.layout_id SET lv.uuid = l.uuid"
  end

  def self.down
     LayoutVersion.update_all("uuid = NULL")
  end
  
  class Layout < ActiveRecord::Base; end
  class LayoutVersion < ActiveRecord::Base; end
end
