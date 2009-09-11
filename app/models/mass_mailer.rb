#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MassMailer < ActionMailer::Base
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::SanitizeHelper

  def mailing(email)
    account = email.account
    if account.owner.own_smtp_account?
      smtp_account = account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
    end

    if email.smtp_email_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(email.smtp_email_account)
    end
    
    raise "Alternate smtp settings not set" unless self.alternate_smtp_settings
  
    self.recipients = email.tos.map(&:to_s).flatten
    self.cc = email.ccs.map(&:to_s).flatten
    self.bcc = email.bccs.map(&:to_s).flatten
    self.from = email.sender.to_s
    self.subject = email.subject
    body_text = email.body

    # Must do attachments at the very end as #add_outline_attachments modifies #body to add links.
    if email.inline_attachments? then
      add_inline_attachments(email)
    else
      add_outline_attachments(email, body_text)
    end

    generate_bodies(email.mail_type, body_text)
  end
  
  def mass_mailing(email, recipient)
    account = email.account
    if account.owner.own_smtp_account?
      smtp_account = account.owner.own_smtp_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(smtp_account)
    end
    
    if email.smtp_email_account
      self.alternate_smtp_settings = SmtpMailer.convert_email_account_to_smtp_settings(email.smtp_email_account)
    end

    raise "Alternate smtp settings not set" unless self.alternate_smtp_settings

    self.from = email.sender.to_s
    self.recipients = recipient.to_s
    self.subject = recipient.generated_subject
    body_text = recipient.generated_body
    generate_bodies(email.mail_type, body_text)

    add_inline_attachments(email) if email.inline_attachments?    
  end

  protected
  def add_inline_attachments(email)
    email.attachments.each do |att|
      attachment :content_type => att.content_type, :body => att.send(:current_data), :filename => att.filename
    end
  end

  def add_outline_attachments(email, body_text)
    return if email.attachments.empty?
    domain = email.account.domain_name

    att_body = ["", "", "-" * 76]
    att_body << "There are #{email.attachments.size} attachment(s) added to this E-Mail.  These documents are stored online.  Please click the link to download them."
    email.attachments.each do |att|
      att_body << sprintf("  %s (%d bytes): %s", att.filename, att.size, download_asset_url(:host => domain, :id => att.asset_id))
    end
    att_body << "-" * 76

    body_text << att_body.join("\n")
  end

  def generate_bodies(mail_type, body_text)
    body_text ||= ""
    case mail_type
    when "Plain"
      self.content_type "text/plain"
      self.body = strip_tags(body_text)
    when "HTML"
      self.content_type "text/html"
      self.body = body_text
    when "HTML+Plain"
      # http://www.caboo.se/articles/2006/02/19/how-to-send-multipart-alternative-e-mail-with-inline-attachments
      self.content_type "multipart/alternative"
      self.part :content_type => "text/plain", :body => strip_tags(body_text).gsub("&nbsp;", " ")
      self.part "multipart/related" do |p|
        p.content_type = "text/html"
        p.part :content_type => "text/html", :body => body_text
      end
    end
  end
end
