#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ActiveMerchant
  module Billing
    class ExactGateway < Gateway
      TRANSACTIONS = { :sale          => "00",
                       :authorization => "01",
                       :capture       => "32",
                       :credit        => "34",
                       :recurring_seed_purchase => "41",
                       :tagged_purchase => "30" }
                       
      def subscribe(money, credit_card, options={})
        commit(:recurring_seed_purchase, build_sale_or_authorization_request(money, credit_card, options))
      end
      
      def pay_subscription(money, authorization, options={})
        commit(:tagged_purchase, build_capture_or_credit_request(money, authorization, options))
      end
    end
  end
end
