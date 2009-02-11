accounts = Account.find(:all, :conditions => ["master=?", 0])
account_owner_email_addresses = accounts.map(&:owner).map(&:email_addresses).flatten.map(&:email_address)
account_owner_email_addresses.reject!(&:blank?)
account_owner_email_addresses.uniq!

puts account_owner_email_addresses.inspect

master_accounts = Account.find(:all, :conditions => ["master=?", 1])

master_accounts.each do |master_account|
  account_owner_email_addresses.each do |email_address|
    party = Party.find_by_account_and_email_address(master_account, email_address)
    next unless party
    party.tag_list += " account_owner"
    party.save!
  end
end