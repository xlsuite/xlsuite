class AddingDefaultGoogleMapsApiKeyConfiguration < ActiveRecord::Migration
  def self.up
    description = "Your google map API key"
    group_name = "Google API"
    config = StringConfiguration.find(:first, :conditions => {:account_id => nil, :name => "google_maps_api_key"})
    if config
      config.description = description
      config.group_name = group_name
    else
      config = StringConfiguration.new(:account_id => nil, :domain_patterns => "**", :description => description, :group_name => group_name, :name => "google_maps_api_key", :str_value => "")
    end
    config.save!
  end

  def self.down
    StringConfiguration.find(:first, :conditions => {:account_id => nil, :name => "google_maps_api_key"}).destroy
  end

  class Configuration < ActiveRecord::Base; end
  class StringConfiguration < Configuration; end
end
