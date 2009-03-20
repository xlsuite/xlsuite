class SettingDomainIdForBlogs < ActiveRecord::Migration
  def self.up
    account_ids = Blog.all(:select => "account_id").map(&:account_id).uniq
    account_ids.each do |account_id|
      begin
        account = Account.find(account_id)
      rescue
        next
      end
      domain = account.canonical_domain
      next unless domain
      Blog.update_all("domain_id = #{domain.id}", "account_id = #{account.id}")
    end
  end

  def self.down
    Blog.update_all("domain_id=NULL")
  end
end
