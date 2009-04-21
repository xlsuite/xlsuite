#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Testimonial < ActiveRecord::Base
  acts_as_taggable
  acts_as_fulltext %w(status), %w(body author_name author_company_name email_address phone_number website_url)

  include DomainPatternsSplitter
  
  auto_scope \
      :all => {},
      :approved => {
          :find => {:conditions => ["approved_at IS NOT NULL AND rejected_at IS NULL"]},
          :create => {}},
      :rejected => {
          :find => {:conditions => ["rejected_at IS NOT NULL"]},
          :create => {}},
      :unapproved => {
          :find => {:conditions => ["rejected_at IS NULL AND approved_at IS NULL"]},
          :create => {}}

  belongs_to :author, :class_name => "Party", :foreign_key => "author_id"
  belongs_to :updated_by, :class_name => "Party", :foreign_key => "updated_by_id"
  belongs_to :created_by, :class_name => "Party", :foreign_key => "created_by_id"
  
  belongs_to :rejected_by, :class_name => "Party", :foreign_key => "rejected_by_id"
  belongs_to :approved_by, :class_name => "Party", :foreign_key => "approved_by_id"

  belongs_to :account
  
  validates_presence_of :account_id, :testified_at, :body, :email_address
  validates_format_of :email_address, :with => EmailContactRoute::ValidAddressRegexp, :allow_nil => true

  before_validation {|r| r.account = r.author.account unless r.author.blank?}

  belongs_to :avatar, :class_name => "Asset", :foreign_key => "avatar_id"
  
  before_validation :set_default_domain_patterns
  before_validation :set_name_and_email_address_based_on_author_info

  def to_liquid
    TestimonialDrop.new(self)
  end
  
  def writeable_by?(party)
    self.author_id == party.id || self.created_by_id == party.id || party.can?(:edit_testimonials)
  end

  def approve!(who)
    self.approved_at = Time.now.utc
    self.approved_by = who
    self.rejected_at = nil
    self.save!
    self.create_party!
    profile = self.author.to_new_profile
    profile.party = self.author
    profile.save!
  end

  def reject!(who)
    self.rejected_at = Time.now.utc
    self.rejected_by = who
    self.approved_at = nil
    self.save!
  end

  def approved?
    self.approved_at
  end

  def rejected?
    self.rejected_at
  end
  
  def unapproved?
    self.approved_at.blank? && self.rejected_at.blank?
  end
  
  def status
    return "Approved" if self.approved?
    return "Rejected" if self.rejected?
    "Unapproved"
  end

  def main_identifier
    "#{self.testified_on} : #{self.author.main_identifier}"
  end
  
  def create_party!
    return false if self.author
    party = self.account.find_or_create_party_by_email_address!(self.email_address, {:name => self.author_name, :company_name => self.author_company_name})
    unless self.phone_number.blank?
      phone = party.main_phone
      phone.account = self.account
      phone.number = self.phone_number
      phone.save!
    end
    unless self.website_url.blank?
      link = party.main_link
      link.account = self.account
      link.url = self.website_url
      link.save!
    end
    party.update_attribute("avatar_id", self.avatar_id) unless party.avatar
    self.update_attributes({:author_id => party.id})
  end
protected
  def author_display_name
    self.author ? self.author.display_name : ""
  end
  
  def set_default_domain_patterns
    self.domain_patterns = "**" if self.domain_patterns.blank?
  end
  
  def set_name_and_email_address_based_on_author_info
    return unless self.author
    self.author_name = self.author.name.to_s unless self.author.name.to_s.blank?
    self.author_company_name = self.author.company_name unless self.author.company_name.blank?
    self.email_address = self.author.main_email.email_address if self.email_address.blank?
  end     
end
