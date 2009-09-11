#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AdminMailer < ActionMailer::Base
  def contact_request_email(current_domain, contact_request)

    cr_recipient_email_address = contact_request.recipients.map do | recipient |
      recipient.main_email.email_address
    end
    
    recipient_email_address = cr_recipient_email_address.join(",")

    default_request_contacts = current_domain.get_config(:default_request_contact).blank? ? current_domain.account.owner.main_email.email_address : current_domain.get_config(:default_request_contact)
    default_request_contacts = default_request_contacts.split(",").map(&:strip).reject(&:blank?).join(",")
    
    recipient_email_address = default_request_contacts if recipient_email_address.blank?
  
    subject_name = ""
    subject_name << "#{current_domain.name.gsub('www.','')} | "

    subject_name << (contact_request.subject || "Contact Request")
    
    bcc_recipients = default_request_contacts.reject{|email|recipient_email_address.index(email)}
    
    recipients recipient_email_address
    bcc        bcc_recipients if current_domain.get_config(:bcc_default_request_contacts) and !bcc_recipients.blank?
    from       "admin@xlsuite.com"
    subject    subject_name
    body       :body => contact_request.body
    content_type "text/html"
  end
  
  def signup_confirmation_email(options={})
    route = options[:route]
    confirmation_url = options[:confirmation_url]
    confirmation_token = options[:confirmation_token]
    confirmation_url = confirmation_url.call(route.routable, confirmation_token) if confirmation_url.respond_to?(:call)
    domain_name = confirmation_url.slice(/\/\/([^\/]+)\//, 1)
    
    from_address = "admin@xlsuite.com"
    account = Domain.find_by_name(domain_name.gsub("www.", "")).account
    if account.get_config(:use_account_owner_smtp) && account.owner.own_smtp_account?
      smtp_account = account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
      from_address = account.owner.main_email.email_address
    end    
    
    recipients route.to_formatted_s
    from from_address
    subject "#{domain_name} Confirmation Email"
    body(:domain_name => domain_name, :confirmation_url => confirmation_url, :confirmation_code => confirmation_token)
    content_type "text/html"
  end
  
  def group_subscribe_confirmation_email(options={})
    route = options[:route]
    confirmation_url = options[:confirmation_url]
    domain_name = confirmation_url.slice(/\/\/([^\/]+)\//, 1)

    from_address = "admin@xlsuite.com"
    account = Domain.find_by_name(domain_name.gsub("www.", "")).account
    if account.get_config(:use_account_owner_smtp) && account.owner.own_smtp_account?
      smtp_account = account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
      from_address = account.owner.main_email.email_address
    end

    recipients route.to_formatted_s
    from from_address
    subject "#{domain_name} Subscription Confirmation Email"
    body(:domain_name => domain_name, :confirmation_url => confirmation_url, :groups => options[:groups])
    content_type "text/html"
  end
  
  def account_confirmation_email(options={})
    parent_domain_name = options[:domain_name].dup
    parent_domain_name = parent_domain_name.split(".")
    parent_domain_name.shift if parent_domain_name.size > 2    
    parent_domain_name = parent_domain_name.join(".")
    recipients options[:route].to_formatted_s
    from "admin@xlsuite.com"
    subject "[XL] Your account registration at #{options[:domain_name]}"
    body(:parent_domain_name => parent_domain_name, :domain_name => options[:domain_name], :confirmation_url => options[:confirmation_url])
    content_type "text/html"
  end
  
  def listing_information(options={})
    recipient = options[:recipient]    
    account_owner = recipient.account.owner
    
    recipients recipient.main_email.to_formatted_s
    from       account_owner.main_email.to_formatted_s
    subject    "List of properties that you might be interested at" 
    body(:public_listing_urls => options[:public_listing_urls], :private_listing_urls => options[:private_listing_urls], 
      :recipient => recipient, :account_owner => account_owner, :forgot_password_url => options[:forgot_password_url])
    content_type "text/html"

    account = recipient.account
    if account.get_config(:use_account_owner_smtp) && account.owner.own_smtp_account?
      smtp_account = account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
    end
  end

  def bug_report_email(options={})
    from_address = nil
    if options[:email_address]
      from_address = options[:email_address].to_s.split(",").map(&:strip).first
      from_address = nil if from_address !~ /#{EmailContactRoute::ValidAddressRegexp}/i
    end
    from_address = options[:current_account].owner.main_email.email_address unless from_address

    account = options[:current_account]
    if account.get_config(:use_account_owner_smtp) && account.owner.own_smtp_account?
      smtp_account = account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
      from_address = account.owner.main_email.email_address
    end

    recipient_email_address = options[:current_account].get_config(:bug_report_recipients) 
    recipient_email_address = options[:current_account].owner.main_email.email_address if recipient_email_address.blank?
    
    recipients recipient_email_address
    from       from_address
    subject    "Bug report: #{options[:subject].inspect}"
    body(:body => options[:body])

    file = options[:attachment_data]
    if file && file.size > 0 then
      attachment :content_type => options[:attachment_data].content_type,
        :body => file.read, :filename => file.original_filename
    end
  end

  def new_order(params)
    @order = params[:order]
    @account = @order.account
    @domain = @order.domain

    recipients params[:recipients]
    from "Order Fullfillment <admin@xlsuite.com>"
    subject "New Order on #{@domain.name}: \##{@order.number}"
    body :order => @order, :account => @account, :customer => @order.invoice_to, :domain => @domain,
        :ship_to => @order.ship_to || @order.invoice_to.main_address
  end
  
  def account_not_activated_email(account)
    account_owner = account.owner
    domain_name = account.domains.first.name
    recipients account_owner.main_email.email_address
    from "admin@xlsuite.com"
    subject "[XL] Your XLsuite account at #{domain_name}"
    content_type "text/html"
    body :domain_name => domain_name, :account_owner => account_owner
  end
  
  def expired_account_deleted_email(account)
    account_owner = account.owner
    domain_name = account.domains.first.name
    recipients account_owner.main_email.email_address
    from "admin@xlsuite.com"
    subject "[XL] Your XLsuite account has been deleted"
    content_type "text/html"
    body :domain_name => domain_name, :account_owner => account_owner
  end
  
  def feed_error_email(feed, error_recipients)
    recipients error_recipients
    from "XLsuite Feed Fetcher <admin@xlsuite.com>"
    subject "[XL] Fatal error retrieving feed: #{feed.label}"
    content_type "text/html"
    body :feed => feed
  end
  
  def account_installed_email(account)
    account_owner = account.owner
    domain_name = account.domains.first.name
    parent_domain_name = account.domains.first.parent ? account.domains.first.parent.name : "XLsuite"
    recipients account_owner.main_email.email_address
    from "admin@xlsuite.com"
    subject "[XL] Your XLsuite account has been installed"
    content_type "text/html"
    body :domain_name => domain_name, :account_owner => account_owner, :parent_domain_name => parent_domain_name
  end
  
  def template_pushed_email(account, template)
    account_owner = account.owner
    domain_name = account.domains.first.name
    recipients account_owner.main_email.email_address
    from "admin@xlsuite.com"
    subject "[XL] Your XLsuite account has been pushed as a Suite"
    content_type "text/html"
    body :domain_name => domain_name, :account_owner => account_owner, :account_template => template
  end
  
  def template_updated_email(account, template)
    account_owner = account.owner
    domain_name = account.domains.first.name
    recipients account_owner.main_email.email_address
    from "admin@xlsuite.com"
    subject "[XL] Your XLsuite account has been updated"
    content_type "text/html"
    body :domain_name => domain_name, :account_owner => account_owner, :account_template => template
  end
  
  def comment_notification(comment, commentable_description, recipient_email)
    domain = comment.domain ? comment.domain : comment.account.domains.first
    domain_name = domain.name

    from_address = "admin@xlsuite.com"
    account = Domain.find_by_name(domain_name.gsub("www.", "")).account
    if account.get_config(:use_account_owner_smtp) && account.owner.own_smtp_account?
      smtp_account = account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
      from_address = accont.owner.main_email.email_address
    end
    
    recipients recipient_email
    from from_address
    subject "New Comment on #{domain_name} on your #{comment.commentable_type.titleize}"
    content_type "text/html"
    body :domain_name => domain_name, :description => commentable_description, :referrer_url => comment.referrer_url 
  end
end
