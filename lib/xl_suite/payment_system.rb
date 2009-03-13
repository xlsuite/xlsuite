#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module PaymentSystem
    class HasBeenPaidInFull < StandardError; end
    class HasNotBeenModified < StandardError; end
  end
end
