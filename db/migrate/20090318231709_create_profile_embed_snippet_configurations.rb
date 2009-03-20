class CreateProfileEmbedSnippetConfigurations < ActiveRecord::Migration
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
      config_group_name = "Profile"
      config_description = "The title of the snippet that is used as a template to generate embed code of a profile"
      config_name = "profile_embed_code_snippet"

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
    Configuration.delete_all(:name => "profile_embed_code_snippet")
  end
end
