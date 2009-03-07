class AddBlackListWordsConfigurations < ActiveRecord::Migration
  def self.up
    config = nil
    config_uuid = UUID.random_create.to_s
    loop do
      unless Configuration.count({:conditions => {:uuid => config_uuid}}) > 0
        break
      end
      config_uuid = UUID.random_create.to_s
    end
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Spam Management"
      config_description = "Automatically mark Comments and Contact Requests as spam if it contains these words. Use comma-separated format to specify multiple words."
      config_name = "blacklist_words"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = config_uuid
      config.str_value = ""
      config.save!      
    end
  end

  def self.down
  end
end
