#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailObserver < ActiveRecord::Observer
  def before_save(email)
    assign_message_id(email)
  end
  
  # TODO do something about email event later
  def after_create(email)
    #EmailEvent.create!(:email => email, :owner => email.sender, :occured_at => Time.now)
  end
  
  protected
  
  def assign_message_id(email)
    email.message_id = self.class.generate_message_id if email.message_id.blank?
  end

  def self.generate_message_id
    "<#{UUID.timestamp_create.to_s}@xlsuite.com>"
  end
end
