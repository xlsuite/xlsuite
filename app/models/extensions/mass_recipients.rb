#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module Extensions
  module MassRecipients
    def unsent
      find(:all, :conditions => {:sent_at => nil})
    end

    def unsent_count
      count(:all, :conditions => {:sent_at => nil})
    end

    def sent
      find(:all, :conditions => "sent_at IS NOT NULL")
    end

    def sent_count
      count(:all, :conditions => "sent_at IS NOT NULL")
    end

    def errored
      find(:all, :conditions => "sent_at IS NULL AND errored_at IS NOT NULL")
    end

    def errored_count
      count(:all, :conditions => "sent_at IS NULL AND errored_at IS NOT NULL")
    end
    
    def waiting_count
      count(:all, :conditions => "sent_at IS NULL AND errored_at IS NULL")
    end

    def to_formatted_s
      array = self.map {|recipient| recipient.to_formatted_s}
      array.join(", ")
    end
  end
end
