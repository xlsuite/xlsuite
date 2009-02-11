class AddDomainSubscriptionConfigurationsToHospitalityxl < ActiveRecord::Migration
  def self.up
    domain = Domain.find_by_name("hospitalityxl.com")
    account = domain.account
    config = ProductConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_1_product", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Product for the first level of domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.save!

    config = IntegerConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_1_quantity", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Quantity of the first level domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.set_value!(1)

    config = ProductConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_2_product", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Product for the second level of domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.save!

    config = IntegerConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_2_quantity", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Quantity of the second level domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.set_value!(4)

    config = ProductConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_3_product", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Product for the third level of domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.save!

    config = IntegerConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_3_quantity", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Quantity of the third level domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.set_value!(5)

    config = ProductConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_4_product", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Product for the fourth level of domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.save!

    config = IntegerConfiguration.find_or_initialize_by_name_and_account_id("domain_subscription_level_4_quantity", account.id)
    config.group_name = "Domain Subscription"
    config.description = "Quantity of the fourth level domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.set_value!(10)

    config = IntegerConfiguration.find_or_initialize_by_name_and_account_id("number_of_domains_for_level_1", account.id)
    config.group_name = "Domain Subscription"
    config.description = "The minimum number of domains for level 1 subscription that is required before proceeding to level 2 domain subscription"
    config.account_wide = true
    config.domain_patterns = "**"
    config.set_value!(1)

    config = IntegerConfiguration.find_or_initialize_by_name_and_account_id("number_of_domains_for_level_2", account.id)
    config.group_name = "Domain Subscription"
    config.description = "The minimum number of domains for level 2 subscription that is required before proceeding to the next cheaper pack"
    config.account_wide = true
    config.domain_patterns = "**"
    config.set_value!(4)
  end

  def self.down
    domain = Domain.find_by_name("hospitalityxl.com")
    account = domain.account

    Configuration.delete_all(:name => [
      "domain_subscription_level_1_quantity", "domain_subscription_level_1_product",
      "domain_subscription_level_2_quantity", "domain_subscription_level_2_product",
      "domain_subscription_level_3_quantity", "domain_subscription_level_3_product",
      "domain_subscription_level_4_quantity", "domain_subscription_level_4_product",
      "number_of_domains_for_level_1", "number_of_domains_for_level_2"
    ], :account_id => account.id)
  end
end
