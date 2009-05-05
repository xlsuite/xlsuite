#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MailSender < Future
  def run
    status!(:initializing, 0)
    emails = Email.pluck_next_ready_mails
    emails.each do |email|
      MethodCallbackFuture.create!(:model => email, :method => :send!, :system => true, :priority => email.priority || 10)
    end

    self.complete!
  end
end
