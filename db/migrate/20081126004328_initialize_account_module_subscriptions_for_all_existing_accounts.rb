class InitializeAccountModuleSubscriptionsForAllExistingAccounts < ActiveRecord::Migration
  def self.up
    InstalledAccountTemplate.all(:conditions => "account_module_subscription_id IS NULL").each do |installed_account_template|
      account = installed_account_template.account   
      
      ActiveRecord::Base.transaction do
        master_account = Account.find_by_master(true)
        account_template = installed_account_template.account_template
        raise "Account template cannot be blank, installed account template id is #{installed_account_template.id}" if account_template.blank?
        i_modules = []
        i_modules += account_template.selected_modules if account_template
        i_modules.uniq!
        raise "Either account template or account module need to be provided to create an account module subscription" if i_modules.empty? && account_template.blank?
        acct_mod_subscription = AccountModuleSubscription.create!(
          :account => account,
          :minimum_subscription_fee => AccountModule.count_minimum_subscription_fee(i_modules),
          :installed_account_modules => i_modules,
          :payment_id => 1)
        payment_description = []
        unless i_modules.empty?
          payment_description << i_modules.map(&:humanize).map(&:downcase).join(', ')
        end      
        payment_description << "#{account_template.name} suite"

        installed_account_template.update_attributes(
          :account_template => account_template,
          :subscription_markup_fee => account_template.subscription_markup_fee,
          :setup_fee => account_template.setup_fee,
          :account_module_subscription => acct_mod_subscription) 

        payment_amount = (account_template ? account_template.subscription_fee : acct_mod_subscription.minimum_subscription_fee) 
        payment = Payment.create!(:account => master_account, :payment_method => "paypal",
          :amount => payment_amount, :payer => account.owner, 
          :description => ("Subscription for #{account.domains.first.name} includes " + payment_description.join(" AND ")))
        payable = Payable.create!(:account => master_account, :amount => payment_amount,
          :payment => payment, :subject => acct_mod_subscription)
      end
      true
      
    end
  end

  def self.down
  end
end
