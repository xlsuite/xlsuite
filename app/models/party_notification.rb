#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PartyNotification < ActionMailer::Base
  def password_reset(options)
    @subject    = "New Password Notification - #{options[:site_name]}"
    @body       = options
    @recipients = options[:party].main_email
    @from       = "Account Manager <admin@xlsuite.com>"
  end
end
