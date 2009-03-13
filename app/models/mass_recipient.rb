#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MassRecipient < Recipient
  def return_to_url
    self.email.return_to_url.blank? ? nil : self.email.return_to_url
  end
  
  def self.find_sent
    self.find(:all, :conditions => 'sent_at IS NOT NULL', :order => "sent_at DESC")
  end
end
