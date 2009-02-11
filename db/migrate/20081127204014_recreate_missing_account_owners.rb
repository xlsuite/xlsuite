class RecreateMissingAccountOwners < ActiveRecord::Migration
  def self.up
    EmailContactRoute.transaction do
      EmailContactRoute.find(:all, :select => "contact_routes.*", :joins => "LEFT JOIN parties ON parties.id = contact_routes.routable_id", :conditions => "parties.id IS NULL AND contact_routes.routable_type = 'Party'").each do |cr|
        # We've found an orphaned contact route, let's see if it's the account owner's
        if account = Account.find_by_id(cr.account_id) then
          if account.party_id == cr.routable_id then
            # Yes, it is
            owner = Party.find_by_account_id_and_id(account.id, account.party_id)
            if owner then
              # Owner still exists?  How come we're here?
              raise "Not supposed to be here!!!"
            else
              party = Party.create!(:account_id => account.id)
              Party.update_all(["id = ?", account.party_id], ["id = ?", party.id])
            end
          else
            # Not the same account owner, so delete the contact route, it's really orphaned
            puts cr.inspect
            cr.destroy
          end
        else
          # Account doesn't even exist?  That's a real, real, orphan
          puts "REAL ORPHAN: #{cr.inspect}"
          cr.destroy
        end
      end
    end
  end

  def self.down
  end

  class Account < ActiveRecord::Base; end
  class Party < ActiveRecord::Base; end
  class ContactRoute < ActiveRecord::Base; end
  class EmailContactRoute < ContactRoute; end
end
