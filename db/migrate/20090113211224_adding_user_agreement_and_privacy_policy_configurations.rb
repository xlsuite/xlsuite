class AddingUserAgreementAndPrivacyPolicyConfigurations < ActiveRecord::Migration
  def self.up
    config = nil
    counter = 0
    user_agreement_uuid = UUID.random_create.to_s
    privacy_policy_uuid = UUID.random_create.to_s
    loop do
      break if user_agreement_uuid != privacy_policy_uuid
      privacy_policy_uuid = UUID.random_create.to_s
    end
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Default page"
      config_description = "Fullslug of the user agreement page"
      config_name = "user_agreement_fullslug"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = user_agreement_uuid
      config.save!
      
      config_description = "Fullslug of the privacy policy page"
      config_name = "privacy_policy_fullslug"
      config_uuid = UUID.random_create.to_s
      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = privacy_policy_uuid
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => ["privacy_policy_fullslug", "user_agreement_fullslug"])
  end
end
