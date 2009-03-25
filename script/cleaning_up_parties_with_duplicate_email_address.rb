account = Account.find_by_master(true)
uniq_email_addresses = account.email_contact_routes.all(:select => :email_address, :conditions => {:routable_type => "Party"}, :group => :email_address).map(&:email_address)
puts uniq_email_addresses.size
uniq_email_addresses.uniq!
puts uniq_email_addresses.size
email_count = 0
party_count = 0
duplicate_email_addresses = []
uniq_email_addresses.each do |email_address|
  email_count = account.email_contact_routes.count(:conditions => {:routable_type => "Party", :email_address => email_address})
  next unless email_count > 1
  duplicate_email_addresses << email_address
end
puts duplicate_email_addresses.inspect
result = {}
ids = nil
duplicate_email_addresses.each do |email_address|
  ids = account.email_contact_routes.all(:select => :routable_id, :conditions => {:routable_type => "Party", :email_address => email_address}).map(&:routable_id)
  result.merge!(email_address => ids)
end
puts result.inspect
ids = []
result.each do |k,v|
  ids += v[1..-1]
end
puts ids.inspect
account.parties.all(:conditions => {:id => ids}).map(&:destroy)
