#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module PaymentConfigurationsHelper
  def insert_payment_gateway_links
    html = "<p>At the moment XLsuite only accepts Versapay E-XACT as card payment processor</p>"
    html += "<p>" + link_to("Don't have a Paypal account? Click here", "https://www.paypal.com/row/cgi-bin/webscr?cmd=_refer-mrb&pal=J87QS2QNXAWKN", :target => "_blank") + "</p>" unless self.current_account.has_paypal?
    html += "<p>" + link_to("Don't have a credit card payment processor? Sign up here", "http://ecommerce.versapay.com/", :target => "_blank") + "</p>" unless self.current_account.has_payment_gateway?
    %Q`
      var paymentGatewayLinksPanel = new Ext.Panel({
        html: #{html.to_json},
        height: 50
      });
      
      wrapperPanel.add(paymentGatewayLinksPanel);
    `
  end
end



