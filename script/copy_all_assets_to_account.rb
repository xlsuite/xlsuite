# This script is used to copy all cms components of an account to another.
# Three input parameters are needed:
#   - Source account domain name: one of the domains in the source account
#   - Target account domain name: one of the domains in the target account

require 'main'

def copy(source_domain, target_domain)
  ActiveRecord::Base.transaction do
    source_account = source_domain.account
    target_account = target_domain.account
    puts "==> Copying assets from #{source_domain.name} to #{target_domain.name}"
    source_account.copy_all_assets_to!(:target_account_id => target_account.id, :overwrite => false)
    puts "==> OPERATION COMPLETED"
  end
end

Main do
  argument("source_domain") { required }
  argument("target_domain") { required }

  def run
    source_domain_name = params["source_domain"].value
    source_domain = Domain.find_by_name(source_domain_name)
    raise "Couldn't not find domain named #{source_domain_name.inspect}" if source_domain.blank?
    
    target_domain_name = params["target_domain"].value
    target_domain = Domain.find_by_name(target_domain_name)
    raise "Couldn't not find domain named #{target_domain_name.inspect}" if target_domain.blank?

    raise "Can't copy cms components within the same account" if source_domain.account == target_domain.account
    copy(source_domain, target_domain)
  end
end
