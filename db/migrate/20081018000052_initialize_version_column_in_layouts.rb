class InitializeVersionColumnInLayouts < ActiveRecord::Migration
  def self.up
    Layout.update_all("version=1")
    Layout.find(:all).each do |l|
      attrs = l.attributes
      attrs.delete("id")
      attrs.merge!(:layout_id => l.id, :version => 1)
      LayoutVersion.create!(attrs)
    end
  end

  def self.down
    Layout.update_all("version=NULL")
    LayoutVersion.delete_all
  end
  
  class Layout < ActiveRecord::Base; end
  class LayoutVersion < ActiveRecord::Base; end
end
