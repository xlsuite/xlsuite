#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'net/pop'

class EmailAccountChecker < Future
  def run
    email_account = EmailAccount.get_next_ready
    return self.complete! if email_account.blank?
    email_account.update_attribute(:updated_at, Time.now.utc)

    # Save the account we were working on
    self.args[:email_account_id] = email_account.id
    self.save(false)
    
    begin
      email_account.retrieve!
    rescue
      #do nothing
    end
    self.complete!
  end
  
  def reschedule_with_args!(*args)
    self.args.delete(:email_account_id)
    reschedule_without_args!(*args)
  end
  alias_method_chain :reschedule!, :args
end
