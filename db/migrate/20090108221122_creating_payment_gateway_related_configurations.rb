class CreatingPaymentGatewayRelatedConfigurations < ActiveRecord::Migration
  def self.up
    config = nil
    counter = 0
    username_uuid = UUID.random_create.to_s
    password_uuid = UUID.random_create.to_s
    loop do
      break if username_uuid != password_uuid
      password_uuid = UUID.random_create.to_s
    end
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Payment Gateway"
      config_description = "The username of your payment gateway"
      config_name = "payment_gateway_username"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = username_uuid
      config.save!
      
      config_description = "The password of your payment gateway"
      config_name = "payment_gateway_password"
      config_uuid = UUID.random_create.to_s
      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = password_uuid
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => ["payment_gateway_password", "payment_gateway_username"])
  end
end
