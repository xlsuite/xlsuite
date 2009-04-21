#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "uuidtools"

# Provides methods to use in #before_save callbacks to generate a UUID.  It is important
# to add an index to your UUID column, as the methods all check that the UUID hasn't been
# used before.
module UuidGenerator
  # Generates a random UUID using UUID's #random_create.
  def generate_random_uuid
    return if self.uuid?
    conditions = {}
    if self.respond_to?(:account_id) && self.respond_to?(:account)
      acct = self.account
      if self.account_id then
        acct = Account.find(self.account_id) unless acct
        conditions.merge!(:account_id => acct.id)
      end
    end
    loop do
      logger.debug {"==> Generating random UUID"}
      self.uuid = UUID.random_create.to_s
      break if self.class.count(:all, :conditions => conditions.merge(:uuid => self.uuid)).zero?
    end
  end

  # Generates a sequential UUID using UUID's #timestamp_create.
  def generate_sequential_uuid
    loop do
      logger.debug {"==> Generating sequential UUID"}
      self.uuid = UUID.timestamp_create.to_s
      break if self.class.count(:all, :conditions => {:uuid => self.uuid}).zero?
    end
  end
end

ActiveRecord::Base.send :include, UuidGenerator
