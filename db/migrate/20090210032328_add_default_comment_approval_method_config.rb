class AddDefaultCommentApprovalMethodConfig < ActiveRecord::Migration
  def self.up
    config = nil
    
    default_comment_approval_method_uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Comments"
      config_description = "Default comment approval method. Can be Moderated, Always approved, or No Comments"
      config_name = "default_comment_approval_method"

      config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.str_value = "Moderated"
      config.uuid = default_comment_approval_method_uuid
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => ["default_comment_approval_method"])
  end
end
