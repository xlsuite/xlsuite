class SettingNullNoUpdateToZero < ActiveRecord::Migration
  def self.up
    Layout.update_all("no_update=0", "no_update IS NULL")
    Page.update_all("no_update=0", "no_update IS NULL")
    Snippet.update_all("no_update=0", "no_update IS NULL")
  end

  def self.down
  end
end
