#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'net/pop'

class Pop3EmailAccount < EmailAccount
  def port
    p = read_attribute(:port)
    p.blank? ? 110 : p
  end

  protected
  # Yields the raw E-Mail text, must return an Email instance.
  def new_mails #:doc:
    Net::POP3.start(self.server, self.port, self.username, self.password) do |pop|
      (pop.mails || []).each do |mail|
        begin
          existing_email = self.account.emails.find_by_unique_id_listing(mail.uidl)
          next if existing_email && existing_email.belongs_to_party(self.party)
          email = yield(mail.pop) if block_given?
          next unless email
          email.unique_id_listing = mail.uidl
          email.save!
          email
        rescue Net::POPError
          logger.warn "Caught POPError while processing mail"
          logger.warn $!
          nil
        end
      end
    end
  end
end
