class NewConfigurationAffiliateAccountSignupEmailTemplate < ActiveRecord::Migration
  def self.up
    config = nil
    
    affiliate_email_template_uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Affiliate"
      config_description = "Label of email template for affiliate signup activation"
      config_name = "affiliate_account_signup_email_template"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.str_value = "affiliate_activation_email"
      config.uuid = affiliate_email_template_uuid
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => ["affiliate_account_signup_email_template"])
  end
end
