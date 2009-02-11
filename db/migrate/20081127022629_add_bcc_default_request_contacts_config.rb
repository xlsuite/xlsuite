class AddBccDefaultRequestContactsConfig < ActiveRecord::Migration
  def self.up
    description = "Some contact requests go to specific parties only. Turn this configuration on to BCC a copy of that contact request to the emails specified in the 'default_request_contact' configuration. "
    group_name = "Contact Request"
    config = BooleanConfiguration.find(:first, :conditions => {:account_id => nil, :name => "bcc_default_request_contacts"})
    if config
      config.description = description
      config.group_name = group_name
    else
      config = BooleanConfiguration.new(:account_id => nil, :domain_patterns => "**", :description => description, :group_name => group_name, :name => "google_maps_api_key", :int_value => 0)
    end
    config.save!
    
    Account.all.each do |account|
      config = BooleanConfiguration.find(:first, :conditions => {:account_id => account.id, :name => "bcc_default_request_contacts"})
      unless config
        BooleanConfiguration.create!(:account_id => account.id, :name => "bcc_default_request_contacts", :domain_patterns => "**", :int_value => 0, :description => description, :group_name => group_name)
      end
    end
  end

  def self.down
  end

  class Configuration < ActiveRecord::Base; end
  class BooleanConfiguration < Configuration; end
end
