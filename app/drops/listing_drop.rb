#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ListingDrop < Liquid::Drop
  delegate :id, :guid, :created_at, :updated_at, :dom_id, :gmap_query, :quick_description, :tag_list, :tags,
           :link, :date, :title, :approved_comments_count, :unapproved_comments_count, :creator, :public?, :to => :listing
  attr_reader :listing

  def initialize(listing)
    @listing = listing
  end

  def address
    @listing.address.to_liquid
  end

  def realtor
    @listing.realtor.to_liquid
  end
  
  def price
    MoneyDrop.new(self.listing.price)
  end
  
  def picture_url
    self.listing.pictures.blank? ? "/images/no-image_small.jpg" : "/admin/assets/#{listing.pictures.first.id}/download?size=square"
  end
  
  def main_picture
    self.listing.pictures.empty? ? nil : AssetDrop.new(self.listing.pictures.first)
  end
  
  def main_flash_file
    self.listing.flash_files.empty? ? nil : AssetDrop.new(self.listing.flash_files.first)
  end
  
  %w(pictures flash_files shockwave_files multimedia audio_files other_files).each do |method_name|
    self.class_eval <<-"end_eval"
      def #{method_name}
        self.listing.#{method_name}.collect {|e| AssetDrop.new(e)}
      end
    end_eval
  end
  
  %w(bedrooms bathrooms broker description extras last_transaction list_date mls_no num_of_images 
    size status style title_of_land year_built open_house_text contact_email region area).each do |attr_name|
    self.class_eval <<-"end_eval"
      def #{attr_name}
        self.listing.#{attr_name}.blank? ? nil : self.listing.#{attr_name}
      end
    end_eval
  end
  
  def meta_description
    "<meta content='#{self.listing.meta_description}' name='description'/>"
  end
  
  def meta_keywords
    "<meta content='#{self.listing.meta_keywords}' name='keywords'/>"
  end
  
  def raw_meta_description
    self.listing.meta_description
  end
  
  def raw_meta_keywords
    self.listing.meta_keywords
  end

  def approved_comments
    self.listing.approved_comments unless self.listing.hide_comments
  end

  def comments_hidden?
    self.listing.hide_comments
  end
  
  def average_rating
    (self.listing.average_comments_rating * 10).round.to_f / 10
  end

  def comments_always_approved
    self.listing.comment_approval_method =~ /always approved/i ? true : false
  end

  def comments_moderated
    self.listing.comment_approval_method =~ /^moderated$/i ? true : false
  end
  
  def comments_off
    self.listing.comment_approval_method =~ /no comments/i ? true : false
  end

  def editable_by_user
    return false unless self.context && self.context["user"] && self.context["user"].party
    return true if self.context["user"].party.can?(:edit_listings)
    return self.context["user"].party.id == self.listing.creator_id
  end
  
  def user_interested
    return false unless self.context && self.context["user"] && self.context["user"].party
    return self.context["user"].party.listings.map(&:id).include?(self.listing.id)
  end
end
