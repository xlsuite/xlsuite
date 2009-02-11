def copy_party_to(account, party)
  puts "Copying party #{party.display_name} with email addresses #{party.email_addresses.map(&:email_address)}"
  party_clone = Party.new(party.attributes)
  party_clone.account_id = account.id
  ActiveRecord::Base.transaction do
    party_clone.save!
    
    %w(email_addresses links phones addresses).each do |contact_routes|
      party.send(contact_routes).each do |contact_route|
        temp = party_clone.send(contact_routes).build(contact_route.attributes)
        temp.account_id = account.id
        temp.save!
      end
    end
  end
end

account_owners = Account.find(:all, :conditions => ["master=?", 0]).map(&:owner)
master_accounts = Account.find(:all, :conditions => ["master=?", 1])

master_accounts.each do |master_account|
  puts "Total party count for master account #{master_account.id} = #{master_account.parties.count}"
  account_owners.each do |account_owner|
    account_owner_email_addresses = account_owner.email_addresses.map(&:email_address)
    party = nil
    account_owner_email_addresses.each do |account_owner_email_address|
      party = Party.find_by_account_and_email_address(master_account, account_owner_email_address)
      break if party
    end
    
    unless party
      copy_party_to(master_account, account_owner)
    end    
  end
  puts "After copying account owners, total party count = #{master_account.parties.count}"
end

