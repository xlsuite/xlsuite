class CreateGigyaSecretKeyConfig < ActiveRecord::Migration
   def self.up
    config = nil
    uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Gigya"
      config_description = "Gigya secret key. Visit http://wiki.gigya.com/030_Gigya_Socialize_API_2.0/020_Socialize_Setup and follow Step 1 to get the secret key"
      config_name = "gigya_socialize_secret_key"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = uuid
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => "gigya_socialize_secret_key")
  end
end
