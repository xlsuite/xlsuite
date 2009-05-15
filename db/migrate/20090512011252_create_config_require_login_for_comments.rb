class CreateConfigRequireLoginForComments < ActiveRecord::Migration
   def self.up
    config = nil
    uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Comments"
      config_description = "If checked, users must be logged in to create comments"
      config_name = "require_login_for_comments"

      config = BooleanConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = uuid
      config.int_value = 1
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => "require_login_for_comments")
  end
end
