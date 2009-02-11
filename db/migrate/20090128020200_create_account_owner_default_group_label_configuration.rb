class CreateAccountOwnerDefaultGroupLabelConfiguration < ActiveRecord::Migration
  def self.up
    master_account = Account.find_by_master(true)
    config_group_name = "Account owners"
    config_description = "The label of a group where all account owners will be in"
    config_name = "account_owner_default_group_label"

    config = StringConfiguration.find_or_initialize_by_name_and_account_id(config_name, master_account.id)
    config.group_name = config_group_name
    config.description = config_description
    config.domain_patterns = "**"
    config.account_wide = true
    config.uuid = UUID.random_create.to_s
    config.save!
    config.set_value!("XLsuite_trial")
  end

  def self.down
    Configuration.delete_all(:name => "account_owner_default_group_label")
  end
end
