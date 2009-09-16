#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Recipient < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation {|r| r.account = r.email.account if r.email }

  belongs_to :email
  belongs_to :party

  acts_as_taggable

  acts_as_fulltext %w(address name)
  serialize :extras

  before_validation :assign_default_address_and_name
  before_create :generate_random_uuid

  def received_at
    self.email.received_at
  end
 
  def sender_name
    return self.email.sender.name if !self.email.nil? && !self.email.sender.nil?
    self.email.sender.name
  end
  
  def sender_address
    self.email.sender.address
  end
  
  def display_name
    return "" unless self.party
    self.party.display_name
  end

  def name
    if read_attribute(:name).blank? && !self.party.blank?
      self.party.name.to_s
    end
    read_attribute(:name)
  end

  def company_name
    self.party.company_name
  end

  def subject
    self.generated_subject.blank? ? self.email.subject : self.generated_subject
  end

  def body
    self.generated_body.blank? ? self.email.body : self.generated_body
  end

  def sent?
    !unsent?
  end

  def unsent?
    sent_at.nil?
  end

  def status
    self.sent? ? :sent : self.email.scheduled? ? :scheduled : :unsent
  end

  def domain_name
    self.email.domain_name
  end

  def liquid_context
    returning({}) do |context|
      context.merge!(
            "recipient" => PartyDrop.new(self.party),
            "from" => PartyDrop.new(self.email.sender.party), "now" => Time.now.utc,
            "attachments" => self.email.attachments.map {|att| AttachmentDrop.new(att, self)},
            "account" => self.email.account, "domain" => self.email.domain)
      context.merge!(self.extras) if self.extras
    end.stringify_keys
  end

  def generate_text!
    self.generated_subject = self.email.subject_template.render(self.liquid_context)
    self.generated_body = self.email.body_template.render(self.liquid_context, {:registers => {"recipient" => self, "account" => self.email.account, "domain" => self.email.domain}})
  end

  def send!(now=Time.now)
    return self.email.mark_bad_recipient!(self, "No E-Mail address defined in Party") \
        if [self.address, self.party.main_email.address].all?(&:blank?)
    return if self.sent?

    self.class.transaction do
      self.generate_text!
      MassMailer.deliver_mass_mailing(self.email, self)
      self.update_attribute(:sent_at, now)
    end

    rescue
      error_message = $!.message.to_s << "\n"
      error_message << $!.backtrace[0,50].join("\n")
      error_message << "\nattributes = #{self.attributes.inspect}"

      self.update_attributes(:errored_at => Time.now.utc, :error_count => self.error_count + 1, :error_backtrace => error_message)
      self.email.mark_bad_recipient!(self, error_message)
  end

  def read!(now=Time.now)
    self.update_attribute(:read_at, now)
  end

  def read?
    self.read_at
  end
  
  def to_formatted_s
    if self.recipient_builder then
      self.recipient_builder.to_s
    else
      addr = self.address.blank? ? self.party.main_email.address : self.address
      
      buffer = []
      buffer << %Q("#{self.name}") unless self.name.blank?

      buffer << "<#{addr}>"
      
      buffer.join(" ")
    end
  end

  def to_s
    returning(self.to_formatted_s.gsub('"', "").strip) do |str|
      if str[0,1] == "<" then
        str.sub!("<", "")
        str.sub!(">", "")
      end
    end
  end
  
  # Must return an Array of EmailContactRoute.
  def email_addresses
    return self.recipient_builder.to_email_addresses if self.recipient_builder
    return [self.party.email_addresses.find_by_address(self.address)] if self.party && self.address
    [EmailContactRoute.new(:email_address => self.address)]
  end
  
  def unsubscribeable_action_handlers
    action_handlers = []
    party = self.party
    self.email.tos.map{|t|t.send("recipient_builder")}.select{|t|t.class==ActionHandlerListBuilder}.each do |builder|
      action_handler = ActionHandler.first(:conditions => {:account_id => self.party.account.id, :id => builder.recipient_builder_id})
      action_handlers << action_handler if action_handler
    end
    action_handlers
  end

  def unsubscribeable_groups
    groups = []
    party = self.party
    self.email.tos.map{|t|t.send("recipient_builder")}.select{|t|t.class==GroupListBuilder}.each do |builder|
      group = party.account.groups.find(builder.recipient_builder_id)
      groups << group if group && party.member_of?(group)
    end
    groups
  end
  
  def unsubscribeable_tags
    tags = []
    party = self.party
    self.email.tos.map{|t|t.send("recipient_builder")}.select{|t|t.class==TagListBuilder}.each do |builder|
      tag = party.tags.find_by_name(Tag.parse(builder.tag_syntax))
      tags << tag if tag
    end
    tags
  end

  class << self
    def find_by_uuid!(uuid)
      find_by_uuid(uuid).if_nil { raise ActiveRecord::RecordNotFound, "Could not find recipient with UUID #{uuid.inspect}" }
    end
  end

  protected
  def recipient_builder
    self.recipient_builder_type.blank? ? nil : self.recipient_builder_type.constantize.new(self)
  end

  def party_display_name
    self.party ? self.party.display_name : nil
  end      

  def assign_default_address_and_name
    return unless self.party
    self.address = self.party.main_email.address if self.address.blank?
    self.name = self.party.name.to_s if self.name.blank?
  end
end
