#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailLabel < ActiveRecord::Base
  has_many :filters
  belongs_to :account
  belongs_to :party
  
  validates_presence_of :party_id, :name, :account_id
  validates_uniqueness_of :name, :scope => :party_id
  
  def validate
    Errors.add(:name, "cannot be Inbox, Outbox, Draft(s), or Sent") if %w(inbox outbox draft drafts sent).include? self.name.downcase
  end
  
  def find_emails
    emails = []
    self.filters.each do |filter|
      emails << filter.emails
    end
    emails.flatten!
    emails.uniq
    emails.sort{|x, y| (y.sent_at || y.received_at || Time.at(0)) <=> (x.sent_at || x.received_at || Time.at(0))}
  end
end
