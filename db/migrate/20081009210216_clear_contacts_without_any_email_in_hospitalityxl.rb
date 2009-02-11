class ClearContactsWithoutAnyEmailInHospitalityxl < ActiveRecord::Migration
  def self.up
    domain = Domain.find_by_name("hospitalityxl.com")
    return unless domain
    account = domain.account
    routable_ids = account.email_contact_routes.all(:conditions => {:routable_type => "Party"}, :select => "routable_id", :group => "routable_id").map(&:routable_id)
    account.parties.all(:conditions => ["parties.id NOT IN (?)", routable_ids]).each_slice(50) do |parties|
      MethodCallbackFuture.create!(:account => account, :models => parties, :method => "destroy")
    end
  end

  def self.down
  end
end
