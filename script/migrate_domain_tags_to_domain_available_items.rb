# This script is used to migrate domain tags of profiles in an account to populate domain_available_items table
# One input parameter is needed: one of the domains in the source account

require 'main'

def migrate_tags_to_domain_available_items(model_name, account)
  domain_names = account.domains.all.map(&:name)
  profile_tags = nil
  domain = nil
  klass = model_name.classify.constantize
  klass.all(:conditions => {:account_id => account.id}).each do |object|
    object_tags = object.tags.map(&:name)
    object_tags.each do |object_tag|
      if domain_names.include?(object_tag)
        domain = Domain.find_by_name(object_tag)
        DomainAvailableItem.create(:item_type => klass.name, :item_id => object.id, :domain_id => domain.id, :account_id => domain.account_id)
      end
    end
  end
end

Main do
  argument("model_name") { required }
  argument("domain_name") { required }

  def run
    model_name = params["model_name"].value
    domain_name = params["domain_name"].value
    domain = Domain.find_by_name(domain_name)
    raise "Couldn't not find domain named #{domain_name.inspect}" if domain.blank?
    
    migrate_tags_to_domain_available_items(model_name, domain.account)
  end
end
