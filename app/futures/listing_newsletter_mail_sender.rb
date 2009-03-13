#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ListingNewsletterMailSender < Future
  validate :args_must_contain_future_ids
  validate :args_must_contain_listing_url

  def run
    futures = self.account.futures.find(self.args[:future_ids])
    
    # schedule one minute later and return if futures's status not completed
    unless futures.all?(&:done?)
      self.reschedule!(1.minute.from_now)
      return
    end
    
    listing_results = []
    futures.each do |future|
      listing_results << future.results[:listings]
    end
    listing_results.compact!
    listing_results.flatten!
    listing_results.uniq!
    
    private_listing_urls = []
    public_listing_urls = []
    listing_results.each do |listing_result|
      listing = self.account.listings.find(listing_result[:id])
      listing_url = self.args[:listing_url].sub(/__id__/i, listing.id.to_s)
      if listing.public?
        public_listing_urls << listing_url
      else
        private_listings_urls << listing_url
      end
    end
    
    recipients = self.account.parties.find_tagged_with(:all => ['newsletter', 'listings'])
    
    recipients.each do |recipient|
      unless (private_listing_urls.blank? && public_listing_urls.blank?)
        body = generate_body(recipient, public_listing_urls, private_listing_urls, self.args[:forgot_password_url], self.account.owner, self.args[:domain_name])
        
        email = self.account.emails.build(:mass_mail => true, :sender => self.account.owner, :current_user => self.account.owner, :return_to_url => "/admin/opt-out/unsubscribed", 
          :opt_out_url => "/admin/opt-out", :tags_to_remove => "listings",
          :message_id => "<#{UUID.timestamp_create.to_s}@xlsuite.com>",
          :scheduled_at => Time.now,
          :subject => "Listings Newsletter", 
          :tos => recipient.main_email.address,
          :body => body)
        email.save!
        email.release
      end
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
  
  def generate_body(recipient, public_listing_urls, private_listing_urls, forgot_password, owner, domain_name)
    body = ""
    body << "<p>Hello #{recipient.name.to_s},</p><p>Please follow the links below to see new listings at #{domain_name.to_s}</p>"
    unless public_listing_urls.blank?
      for listing_url in public_listing_urls
        body << "\n- #{listing_url}"
      end
    end
    unless private_listing_urls.blank?
      for listing_url in private_listing_urls
        body << "\n- #{listing_url}"
      end
    end
    body << "<p>Thank you,</p><p>#{owner.name.to_s}</p><p>#{owner.main_phone}</p>"
    body << "<p>If you feel you have received this email in error, or would like to remove yourself from future mailings, simply opt out here : {% opt_out_url domain: '#{domain_name.to_s}'%}, Thank you.</p>"
  end
  
end
