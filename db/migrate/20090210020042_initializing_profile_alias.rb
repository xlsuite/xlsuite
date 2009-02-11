class InitializingProfileAlias < ActiveRecord::Migration
  def self.up
    Profile.all(:conditions => "display_name <> ''").each do |profile|
      profile.send(:generate_alias)
    end
  end

  def self.down
    Profile.update_all("alias=NULL")
  end
end
