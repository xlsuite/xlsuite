#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Referral < ActiveRecord::Base
  belongs_to :account
  belongs_to :referrer, :class_name => "Party", :foreign_key => :party_id
  belongs_to :email
  belongs_to :reference, :polymorphic => true

  attr_accessor :friends, :from, :subject, :body, :return_to, :title, :contact

  validates_format_of :referral_url, :with => /^https?:\/\//i
  validate :validate_friend_addresses, :validate_sender_address, :validate_at_least_one_friend

  DEFAULT_SUBJECT = "Check this out!"

  before_create :generate_random_uuid
  before_create :associate_referrer
  before_create :create_email
  before_create :create_recipients

  def after_initialize
    self.from = Friend.new if self.from.blank?
    self.friends = [] if self.friends.blank?
    self.subject = "Check this out!" if self.subject.blank?
  end

  def title
    @title || self.referral_url
  end

  def to_param
    self.uuid
  end

  def referrer_name
    if self.referrer.blank? && self.from.name.blank? then
      "<your name>"
    elsif self.referrer.blank? then
      self.from.name
    else
      self.referrer.name.first
    end
  end

  def default_body(force=false)
    text = <<EOF
Your friend, #{self.referrer_name}, wants you to click:

#{title}
#{referral_url}
EOF

    text << "\nYour friend said:\n" if force || !self.body.blank?
    text
  end

  def contact_body(force=false)
    text = <<EOF
#{self.referrer_name} is inquiring about:

#{title}
#{referral_url}
EOF

    text << "\n#{self.referrer_name} says: " if force || !self.body.blank?
    text
  end

  protected
  def validate_friend_addresses
    return if self.friends.blank?
    self.friends.each do |friend|
      logger.debug {"==> Validating #{friend.email.inspect}"}
      self.errors.add_to_base("#{friend.email.inspect} is an invalid address") \
          unless EmailContactRoute.valid_address?(friend.email)
    end
  end

  def validate_sender_address
    self.errors.add_to_base("No sender address specified") if self.from.blank? || self.from.email.blank?
    self.errors.add_to_base("Invalid sender E-Mail address specified") \
        unless EmailContactRoute.valid_address?(self.from.email)
  end

  def associate_referrer
    return unless self.referrer.blank?
    self.referrer = find_or_create_party_by_name_and_email_address(self.from.name, self.from.email)
  end

  def create_email
    self.email = Email.create!(:mass_mail => true, :account => self.account, :subject => self.subject || DEFAULT_SUBJECT,
        :body => "#{self.contact ? self.contact_body : ""}#{self.body.gsub('<your name>', self.referrer_name)}", :sender => self.referrer(true))
  end

  def create_recipients
    return if self.friends.blank?
    self.friends.each do |friend|
      next if friend.email.blank?
      self.email.tos.create(:account => self.account, :address => friend.email,
          :name => friend.name, :party => friend.to_party(self.account))
    end
  end

  def find_or_create_party_by_name_and_email_address(name, email_address)
    party = Party.find_by_account_and_email_address(self.account, email_address)
    return party if party

    returning self.account.parties.build do |party|
      party.set_name(name)
      party.save!
      party.main_email.update_attributes!(:email_address => email_address)
    end
  end

  def validate_at_least_one_friend
    self.errors.add_to_base("Did you forget to enter a friend's address?") if self.friends.blank?
  end
end
