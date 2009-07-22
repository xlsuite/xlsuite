class InitializeDomainIdAndAccountIdInAffiliateAccountTrackings < ActiveRecord::Migration
  def self.up
    target_url = nil
    domain = nil
    AffiliateAccountTracking.all.each do |tracking|
      target_url = tracking.target_url
      target_url = target_url.split("/").reject(&:blank?)[1]
      domain = Domain.find_by_name(target_url)
      next unless domain
      tracking.domain_id = domain.id
      tracking.account_id = domain.account.id
      tracking.save!
    end
  end

  def self.down
  end
end
