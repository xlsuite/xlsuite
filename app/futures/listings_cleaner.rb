#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ListingsCleaner < Future
  before_validation :set_system_flag
  before_validation :set_scheduled_at

  def run
    Listing.find(:all, :conditions => ["type IS NULL AND updated_at <= ?", 8.days.ago],
              :order => "updated_at", :limit => 100).each do |listing|
      case listing.status
      when /^active$/i
        # save the listing to update the updated_at field 
        # TODO: this is going to be no good later on after we implemented the rets listing updator
        # would need a cleaned_at field at that time
        listing.save
        next
      when /^sold$/i
        # proceed to the next item if listing is tagged with "sold"
        next if listing.tag_list.split(",").map(&:strip).index("sold")
        # delete if the listing is not account owner's
        owner_email_addresses = listing.account ? listing.account.owner.email_addresses.map(&:email_address) : []
        next if owner_email_addresses.index(listing.contact_email)
        listing.destroy
      else
        listing.destroy
      end
    end
    self.complete!
  end
  
  protected
  def set_system_flag
    self.system = true
  end
  
  def set_scheduled_at
    self.scheduled_at = Time.now unless self.scheduled_at
  end
end
