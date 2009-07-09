class InitializeAffiliateAccountsForAllConfirmedContacts < ActiveRecord::Migration
  def self.up
    Party.all(:conditions => {:confirmed => true}).each do |party|
      party.convert_to_affiliate_account!
    end
  end

  def self.down
  end
end
