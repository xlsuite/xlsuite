#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Friend
  attr_accessor :name, :email

  def initialize(params={})
    @name = params[:name]
    @email = params[:email]
    yield self if block_given?
  end

  def dom_id
    @dom_id ||= "friend_#{Friend.dom_id!}"
  end

  def self.dom_id!
    @dom_id ||= Time.now.to_i
    @dom_id += 1
  end

  def to_party(account)
    party = Party.find_by_account_and_email_address(account, self.email)
    if party.blank? then
      party = account.parties.build
      party.set_name(self.name)
      party.save!
      party.main_email.update_attributes!(:email_address => self.email)
    end

    party
  end

  def ==(other)
    self.eql?(other)
  end

  def eql?(other)
    name == other.name && email == other.email
  end

  def hash
    name.hash + email.hash
  end
end
