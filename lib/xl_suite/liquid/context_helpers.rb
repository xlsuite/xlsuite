#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module Liquid
    module ContextHelpers
      def current_user
        self.registers["user"]
      end
      
      def current_user?
        !current_user.blank?
      end
      
      def current_domain
        self.registers["domain"]
      end
      
      def current_account
        self.registers["account"]
      end
      
      def page_url
        self.registers["page_url"]
      end
      
      def recipient
        self.registers["recipient"]
      end
    end
  end
end
