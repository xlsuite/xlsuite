class SettingLastVisitedAtInCachedPages < ActiveRecord::Migration
  def self.up
    CachedPage.update_all(["last_visited_at = ?", Time.now.utc])
  end

  def self.down
    CachedPage.update_all("last_visited_at = NULL")
  end
end
