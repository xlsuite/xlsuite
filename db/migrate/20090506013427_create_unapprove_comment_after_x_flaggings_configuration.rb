class CreateUnapproveCommentAfterXFlaggingsConfiguration < ActiveRecord::Migration
   def self.up
    config = nil
    uuid = UUID.random_create.to_s
    
    Account.all(:select => "id").map(&:id).each do |account_id|
      config_group_name = "Comments"
      config_description = "Automatically unapprove comments after x number of flaggings. Set to 0 to turn this feature off."
      config_name = "unapprove_comment_after_x_flaggings"

      config = IntegerConfiguration.find_or_initialize_by_name_and_account_id(config_name, account_id)
      config.group_name = config_group_name
      config.description = config_description
      config.domain_patterns = "**"
      config.account_wide = true
      config.uuid = uuid
      config.int_value = 0
      config.save!
    end
  end

  def self.down
    Configuration.delete_all(:name => "unapprove_comment_after_x_flaggings")
  end
end
