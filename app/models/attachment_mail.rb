#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AttachmentMail < ActionMailer::Base
  def authorization(options)
    logger.debug "START - #{self.class.name}\#authorization(#{options.inspect})"
    begin
    from        "#{options[:attachment].owner.name.to_forward_s} <#{options[:attachment].owner.email}>"
    recipients  "#{options[:authorization].name} <#{options[:authorization].email}>"
    subject     "Access Authorization: '#{options[:attachment].title}'"
    body        options
    ensure
      logger.debug "END   - #{self.class.name}\#authorization(...)"
    end
  end
end
