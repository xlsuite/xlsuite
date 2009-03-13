#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MailReader < ActionMailer::Base
  cattr_accessor :account, :user

  def receive(mail)
    begin
      raise ArgumentError, "No #account defined (it is nil).  Call MailReader#account= before calling MailReader#receive" \
          if MailReader.account.blank?
      raise ArgumentError, "No #user defined (it is nil).  Call MailReader#user= before calling MailReader#receive" \
          if MailReader.user.blank?
      Email.transaction do
        real_receive(mail, user)
      end
    ensure
      MailReader.account = nil
      MailReader.user = nil
    end
  end

  protected
  def real_receive(mail, user)
    current_account = MailReader.account

    logger.info "Receiving mail with ID: #{mail.message_id}"
    email = current_account.emails.find_by_message_id(mail.message_id)
    logger.info "Email found? #{!email.nil?}"
    return email if email && email.belongs_to_party(user)
    
    if email && !email.belongs_to_party(user)
      return create_secondary_recipient(email)
    end

    sender_address_header = mail.from_addrs.first

    return if sender_address_header.local !~ EmailContactRoute::ValidAddressRegexp

    sender_party = party_from_address(sender_address_header.local, sender_address_header.name)
    email = current_account.emails.build(:message_id => mail.message_id, :current_user => sender_party,
        :subject => mail.subject, :received_at => mail.date)
    sender_recipient = email.build_sender(:party => sender_party, :address => mail.from_addrs.first.local,
        :name => mail.from_addrs.first.name, :account => current_account)
    email.save!

    email.body = ''
    if mail.multipart? then
      attachments, bodies = mail.parts.partition {|part| part.disposition_param('filename')}
      bodies.each do |part|
        email.body << part.body if part.content_type =~ %r{^text/plain}i
      end

      bodies.each do |part|
        email.body << strip_tags(part.body) if part.content_type =~ %r{^text/}i
      end if email.body.blank?

      attachments.each do |part|
        asset = current_account.assets.create!(
          :title => part.disposition_param("filename"),
          :owner => sender_party, :filename => part.disposition_param("filename"),
          :content_type => part.content_type, :temp_data => part.body)
        email.attachments.create!(:asset => asset)
      end

    else
      email.body = mail.body
    end

    %w(to cc bcc).each do |source|
      next if mail.send("#{source}_addrs").blank?
      mail.send("#{source}_addrs").each do |addr|
        next unless addr.respond_to?("local")

        recipient = email.send("#{source}s").create!(:party => party_from_address(addr.local, addr.name),
          :address => addr.local, :name => addr.name, :account => current_account)
        recipient.tag('inbox')
      end

      # use X-Original-To or Delivered-To fields inside the mail for emails that only contain BCCs 
      email_addresses = (email.tos.map(&:email_addresses) + email.ccs.map(&:email_addresses) + email.bccs.map(&:email_addresses)).flatten
      bcc_email_address = mail["X-Original-To"].body if mail["X-Original-To"]
      bcc_email_address = mail["Delivered-To"].body if mail["Delivered-To"] && bcc_email_address.blank?
      
      if !bcc_email_address.blank? && !email_addresses.index(bcc_email_address) 
        # it has to be an email that has only bcc recipients, 
        party = party_from_address(bcc_email_address)      
        bcc_recipient = email.bccs.build(:party => party,
              :address => bcc_email_address,
              :name => party.name.to_s,
              :account => current_account)
        bcc_recipient.tag("inbox")
      end
      
      email.save!
      email.apply_filters(user)
    end

    returning(email) do
      create_secondary_recipient(email) unless email.belongs_to_party(user)
    end
  end

  protected
  def create_secondary_recipient(email)
    Email.transaction do
      begin
        recipient = email.secondaries.build
        recipient.attributes = {:party => user, :account => account}
        recipient.tag_list = 'inbox'
        email.save!
        email
      rescue 
        logger.error {"Error saving secondary email:#{$!}\n#{$!.backtrace.join("\n")}"}
      end
    end
  end
  
  def party_from_address(address, name="")
    account = MailReader.account
    email_address = account.email_contact_routes.find_by_address_and_routable_type(address, "Party")
    return email_address.routable if email_address

    Party.transaction do
      returning account.parties.create!(:last_name => name) do |party|
        EmailContactRoute.create!(:name => "Main", :address => address, :routable => party)
      end
    end
  end

  # Copied from ActionView::Helpers::TextHelper.
  def strip_tags(html)
    if html.index("<")
      text = ""
      tokenizer = HTML::Tokenizer.new(html)

      while token = tokenizer.next
        node = HTML::Node.parse(nil, 0, 0, token, false)
        # result is only the content of any Text nodes
        text << node.to_s if node.class == HTML::Text
      end
      # strip any comments, and if they have a newline at the end (ie. line with
      # only a comment) strip that too
      text.gsub(/<!--(.*?)-->[\n]?/m, "")
    else
      html # already plain text
    end
  end
end
