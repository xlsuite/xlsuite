#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ListingRecipientsMailSender < Future
  validate :args_must_contain_future_ids
  validate :args_must_contain_listing_url

  def run
    futures = self.account.futures.find(self.args[:future_ids])
    
    # schedule one minute later and return if futures's status not completed
    unless futures.all?(&:done?)
      self.reschedule!(1.minute.from_now)
      return
    end
    
    recipients = []
    futures.each do |future|
      future.args[:recipients].reject(&:blank?).each do |recipient|
        party = self.account.parties.find_by_id(recipient.split("_").last)
        recipients << party if party
      end
    end
    recipients.uniq!
    
    recipients.each do |recipient|
      listing_results = []
      futures.each do |future|
        listing_results << future.results[:listings] if future.contain_recipient?(recipient)
      end
      listing_results.compact!
      listing_results.flatten!
      listing_results.uniq!
      
      private_listing_urls = []
      public_listing_urls = []
      listing_results.each do |listing_result|
        listing = self.account.listings.find(listing_result[:id])
        listing_url = self.args[:listing_url].sub("__id__", listing.id.to_s)
        if listing.public?
          public_listing_urls << listing_url
        else
          private_listings_urls << listing_url
        end
      end
      
      AdminMailer.deliver_listing_information(:recipient => recipient, :forgot_password_url => args[:forgot_password_url],
        :public_listing_urls => public_listing_urls, :private_listing_urls => private_listing_urls) \
        unless recipient.main_email.new_record? || (private_listing_urls.blank? && public_listing_urls.blank?)
    end
    
    self.complete!
  end

  protected
  def args_must_contain_future_ids
    self.errors.add_to_base("args does not contain an entry named :future_ids") unless self.args.has_key?(:future_ids)
    self.errors.add_to_base("future_ids key can't be blank") if self.args.has_key?(:future_ids) && self.args[:future_ids].blank?
  end
  
  def args_must_contain_listing_url
    self.errors.add_to_base("args does not contain an entry named :listing_url") unless self.args.has_key?(:listing_url)
    self.errors.add_to_base("listing_url key can't be blank") if self.args.has_key?(:listing_url) && self.args[:listing_url].blank?
  end
  
  def args_must_contain_forgot_password_url
    self.errors.add_to_base("args does not contain an entry named :forgot_password_url") unless self.args.has_key?(:forgot_password_url)
    self.errors.add_to_base("forgot_password_url key can't be blank") if self.args.has_key?(:forgot_password_url) && self.args[:forgot_password_url].blank?
  end
end
