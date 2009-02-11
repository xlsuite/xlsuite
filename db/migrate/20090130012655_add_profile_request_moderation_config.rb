class AddProfileRequestModerationConfig < ActiveRecord::Migration
  def self.up
    config = nil
    
    profile_request_moderation_uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Profile"
      config_description = "Enable moderation for profile requests."
      config_name = "profile_request_moderation"

      config = BooleanConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.int_value = 1
      config.uuid = profile_request_moderation_uuid
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => ["profile_request_moderation"])
  end
end
