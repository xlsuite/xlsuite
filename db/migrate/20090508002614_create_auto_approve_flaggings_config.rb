class CreateAutoApproveFlaggingsConfig < ActiveRecord::Migration
   def self.up
    config = nil
    uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Flaggings"
      config_description = "Automatically approve flaggings."
      config_name = "auto_approve_flagging"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = uuid
      config.str_value = "off"
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => "auto_approve_flagging")
  end
end
