class AddGoogleMapApiKeyConfigToAllAccounts < ActiveRecord::Migration
  def self.up
    description = "Your google map API key"
    group_name = "Google API"
    
    Account.all.each do |account|
      config = StringConfiguration.find(:first, :conditions => {:account_id => account.id, :name => "google_maps_api_key"})
      unless config
        StringConfiguration.create!(:account_id => account.id, :name => "google_maps_api_key", :domain_patterns => "**", :str_value => "", :description => description, :group_name => group_name)
      end
    end
  end

  def self.down
  end

  class Configuration < ActiveRecord::Base; end
  class StringConfiguration < Configuration; end
end
