class DeletingBackgroundPageFullslugConfiguration < ActiveRecord::Migration
  def self.up
    Configuration.delete_all({:name => "background_page_fullslug"})
  end

  def self.down
  end
end
