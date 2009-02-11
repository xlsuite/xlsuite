class CreateUserPrivatePageConfig < ActiveRecord::Migration
  def self.up
    config = nil
    
    user_private_page_uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Default page"
      config_description = "Fullslug of the user private page"
      config_name = "user_private_fullslug"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.str_value = "/private"
      config.uuid = user_private_page_uuid
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => ["user_private_fullslug"])
  end
end

