class CreatingUseAccountOwnerSmtpBooleanConfiguration < ActiveRecord::Migration
  def self.up
    config = nil
    smtp_uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "SMTP Setting"
      config_description = "When checked most admin emails will be sent through the SMTP account of the account owner"
      config_name = "use_account_owner_smtp"

      config = BooleanConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = smtp_uuid
      config.int_value = 0
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => "use_account_owner_smtp")
  end
end
