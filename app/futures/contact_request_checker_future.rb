#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ContactRequestCheckerFuture < Future
  def run
    begin
      domain = Domain.find(args[:domain_id])
      obj = ContactRequest.find(args[:id])
      obj.do_spam_check!
      obj.confirm_as_ham! if !domain.get_config(:enable_contact_request_spam_check)
      
      if obj.reload.approved_at
        AdminMailer.deliver_contact_request_email(domain, obj) if domain
          
        errors = obj.create_party
        self.results[:party_save_error] = errors if errors
      end
    rescue
      self.results[:errors] = $!.message
      self.results[:backtrace] = $!.backtrace.join("\n")
    end
    self.complete!
  end
end
