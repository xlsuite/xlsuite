#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CustomerNotification < ActionMailer::Base
  def new_account(params={}, sent_at = Time.now)
    subject     "New Account @ #{params[:domain]}"
    body        params
    recipients  params[:customer].main_email.to_formatted_s
    from        "Account System #{params[:domain]} <admin@xlsuite.com>"
    sent_on     sent_at
  end

  def payment_received(params={}, sent_at = Time.now)
    payment = params[:payment]
    payable = payment.payables.latest
    payable_subject = payable.subject
    payable_subject = payable_subject.subject if payable_subject.kind_of?(Subscription)
    customer = payable_subject.customer
    domain = params[:domain].kind_of?(Domain) ? params[:domain] : payment.account.canonical_domain
    mail_domain = domain.to_mail_domain
      
    needs_to_ship = needs_to_download = false
    unless payable_subject.kind_of?(AccountModuleSubscription)
      payable_subject.lines.each do |l|
        needs_to_ship = true if l.product && l.product.accessible_items.blank? && !(l.product.classification =~ /service/i)
        needs_to_download = true if l.product && !l.product.accessible_items.blank?
      end
    end
    
    confirmation_url = nil
    download_page = "http://#{domain.name}" + domain.get_config(:user_private_fullslug)
    if needs_to_download && !customer.confirmed?
      customer.confirmation_token_expires_at = customer.account.get_config(:confirmation_token_duration_in_seconds).from_now \
            if customer.confirmation_token_expires_at.blank?
      customer.confirmation_token = UUID.random_create.to_s
      customer.save!
      confirmation_url = confirm_party_url(:id => customer, :code => customer.confirmation_token, :signed_up => download_page, 
          :return_to => params[:return_to], :host => domain.name)
    end
    
    subject_value = ""
    case payable.subject # can be Subscription, AccountModuleSubscription and Order
    when Subscription
      subject_value = "[XL] Automated payment for your XLsuite subscription of #{payable_subject.class.name.humanize} ##{payable_subject.number} for #{payment.amount.format}"
    else
      subject_value = "[XL] Confirmation of your #{payable_subject.class.name.humanize} ##{payable_subject.number} for #{payment.amount.format}"
    end
    
    reset_password_url = "http://#{domain.name}/admin/parties/forgot_password"

    from_address = "admin@xlsuite.com"
    if payable_subject.account.get_config(:use_account_owner_smtp) && payable_subject.account.owner.own_smtp_account?
      smtp_account = payable_subject.account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
      from_address = payable_subject.account.owner.main_email.email_address
    end

    subject    subject_value
    body       params.merge(:payment => payable.payment, :payable_subject => payable_subject, :customer => customer, :needs_to_ship => needs_to_ship, 
                            :needs_to_download => needs_to_download, :download_page => download_page, :confirmation_url => confirmation_url,
                            :reset_password_url => reset_password_url)
    recipients customer.main_email.to_formatted_s
    from       "Payment Processor #{domain} <#{from_address}>"
    sent_on    sent_at
    content_type "text/html"
  end
end
