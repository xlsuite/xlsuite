#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailDrop < Liquid::Drop
  delegate :name, :email_address, :to => :email
  attr_reader :email

  def initialize(email)
    @email = email
  end
end
