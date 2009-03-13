#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'digest/sha1'

class AssetAuthorization < ActiveRecord::Base
  belongs_to :attachment
  belongs_to :account

  before_create :generate_private_key
  before_create :generate_url_hash

  attr_accessible :email, :name, :expires_on, :expires_at

  before_validation {|r| r.account = r.attachment.account if r.attachment}
  
  def expires_on
    return nil unless self.expires_at
    self.expires_at.to_date - 1
  end

  def expires_on=(date)
    dt = case date
    when Date, Time, DateTime
      date
    when String
      case date
      when /^(\d{4})(\d{2})(\d{2})$/
        Date.new($1.to_i, $2.to_i, $3.to_i)
      else
        range = Chronic.parse(date, :guess => false)
        return self.errors.add(:expires_on, 'is invalid') unless range
        range.first
      end
    else
      raise ArgumentError, "Expected a Date, Time, DateTime or String; got a #{date.class.name}"
    end

    write_attribute(:expires_at, dt.to_time + 24.hours)
  end

  def attempt_access!(options={})
    options[:accessed_at] = Time.now unless options[:accessed_at]

    raise AuthorizationFailure, 'Authorization expired' if self.expires_at && self.expires_at < options[:accessed_at]
    raise AuthorizationFailure, 'Wrong URL Hash' if self.url_hash != options[:url_hash]
    raise AuthorizationFailure, 'Wrong E-Mail' if options[:email] && self.email != options[:email]
    raise AuthorizationFailure, 'Wrong cookie hash' if options[:cookie_hash] && self.cookie_hash != options[:cookie_hash]
    raise AuthorizationFailure, 'No access information' if options[:cookie_hash].blank? && options[:email].blank?

    if self.cookie_hash.blank? then
      self.cookie_hash = self.class.sha1("#{Time.now.to_i + rand(100000000)}--#{self.url_hash}")
      self.cookie_instantiation_count += 1
    end

    self.download_count += 1

    rescue AuthorizationFailure
      self.unauthorized_access_attempts_count += 1
      raise

    ensure
      self.save!
  end

  def send!(download_url)
    logger.debug "#{self.class.name}\#send!(#{download_url.inspect})"
    AttachmentMail.deliver_authorization(:attachment => self.attachment,
        :authorization => self, :download_url => download_url)
  end

  def self.find_by_url_hash!(url_hash)
    auth = self.find(:first, :conditions => ['url_hash = ?', url_hash],
        :include => {:attachment => :owner})
    raise ActiveRecord::RecordNotFound unless auth
    auth
  end

  def main_identifier
    "#{self.attachment.filename} : #{self.name}"
  end
  protected
  # Generate a new private key only if none already exists.
  def generate_private_key
    self.private_key = Time.now.to_i + rand(100000000)
  end

  def url_hash_value
    date = self.expires_at ? self.expires_at : Time.now
    "#{self.email}--#{self.private_key}--#{self.attachment_id}--#{date.to_formatted_s}"
  end

  # Always generate a new Hash value, since if any component changes (E-Mail,
  # expiry date), we want to hand out a new authorization.
  def generate_url_hash
    self.url_hash = self.class.sha1(self.url_hash_value)
  end

  def self.sha1(value)
    Digest::SHA1.hexdigest(value)
  end
end
