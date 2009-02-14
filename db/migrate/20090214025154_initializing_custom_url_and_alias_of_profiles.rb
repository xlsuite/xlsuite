class InitializingCustomUrlAndAliasOfProfiles < ActiveRecord::Migration
  def self.up
    Profile.all(:conditions => "account_id <> 2330").each do |profile|
      profile.send(:generate_alias)
      profile.send(:generate_custom_url)
    end
  end

  def self.down
    Profile.update_all("alias=NULL, custom_url=NULL")
  end
end
