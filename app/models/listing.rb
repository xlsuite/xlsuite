#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'net/http'
require 'uri'
require 'open-uri'
require 'RMagick'
require "white_list_helper"

class Listing < ActiveRecord::Base
  include XlSuite::Commentable
  acts_as_reportable

  include WhiteListHelper
  include XlSuite::PicturesHelper
  
  belongs_to :account
  validates_presence_of :account_id

  acts_as_taggable
  acts_as_fulltext %w(quick_description), %w(address_as_text mls_no realtor_name tags_as_text description status region contact_email)
  
  has_one :address, :class_name => "AddressContactRoute", :as => :routable, :dependent => :destroy
  belongs_to :realtor, :class_name => 'Party', :foreign_key => 'realtor_id'
  belongs_to :creator, :class_name => 'Party', :foreign_key => 'creator_id'
  
  has_many :interests, :dependent => :destroy
  has_many :parties, :through => :interests

  has_many :audio_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::AUDIO_FILES_CONDITION
  has_many :flash_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::FLASH_FILES_CONDITION
  has_many :shockwave_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::SHOCKWAVE_FILES_CONDITION
  has_many :multimedia, :source => :asset, :through => :views, :order => "views.position", :conditions => ["views.classification=?", "multimedia"]
  has_many :other_files, :source => :asset, :through => :views, :order => "views.position", :conditions => ["views.classification=?", "other_files"]

  attr_accessor :overwrite_attributes
  
  acts_as_money :price, :allow_nil => false
  acts_as_geolocatable

  serialize :raw_property_data, Hash

  validates_uniqueness_of :external_id, :allow_nil => true, :scope => :account_id

  before_validation :set_open_house_text_to_nil_if_blank
  before_create :generate_random_uuid
  before_save :set_attributes_using_raw_data
  before_save :set_default_attributes
  before_save :assign_raw_property_data
  before_save :copy_geolocation_from_address
  before_save :set_open_house_flag

  before_save  do |l|
    l.public = (l.raw["Internet ok"].blank? || l.raw["Internet ok"] =~ /^yes$/i ? true : false)
    #Changing status of a listing to "sold" if tag_list contains "sold"
    l.status = "Sold" if l.tag_list.include?("sold")
    true
  end
  
  before_save do |l|
    if l.public? then
      l.tag_list += " public" if l.public? && !l.tag_list.include?("public")
    else
      l.tag_list = l.tag_list.gsub("public", "") if l.tag_list.include?("public")
    end
  end
  
  after_destroy :destroy_files
  
  UNITS = %w(acres sqft m2).sort.to_selection_list
  
  def change_to_private
    self.public = false
    self.raw_property_data["Internet ok"] = "No"
  end
  
  def from_external_source?
    !self.external_id.blank?
  end
  
  def raw(field_name=nil)
    self.raw_property_data ||= {}
    if field_name then
      self.raw_property_data[field_name]
    else
      self.raw_property_data
    end
  end

  def realtor_name
    self.realtor ? self.realtor.display_name : nil
  end

  def quick_description
    out = []
    out << self.address.line1 if self.address
    out << self.area
    out << self.city
    out << self.zip 
    out.delete_if(&:blank?)
    out.blank? ? "no info" : out.join(", ")
  end
  
  def raw_property_data
    @temp_raw_property_data ||= read_attribute(:raw_property_data) || {}
    @temp_raw_property_data
  end
  
  def raw_property_data=(new_hash)
    raise ArgumentError, "raw_property_data must be a hash" unless new_hash.kind_of?(Hash)
    @temp_raw_property_data = new_hash
  end

  def age=(num)
    self.raw_property_data.merge!({"Age" => num})
  end
  
  def year_built=(num)
    self.raw_property_data.merge!({"Approx. Year Built" => num})
  end

  def bedrooms=(num)
    self.raw_property_data.merge!({"Total Bedrooms" => num})
  end
  
  def bathrooms=(num)
    self.raw_property_data.merge!({"Total Baths" => num})
  end
  
  def mls_no
    read_attribute(:mls_no) || raw["MLS Number"]
  end
  
  def age
    [raw["Age"], raw["Age Type"]].reject(&:blank?).join(" ")
  end

  def bedrooms
    raw["Total Bedrooms"]
  end

  def bathrooms
    raw["Total Baths"]
  end

  def city
    self.address.city
  end
  
  def province
    self.address.state
  end
  
  def style
    raw["Style of Home"]
  end
  
  def size
    raw["Floor Area -Grand Total "]
  end
  
  def zip
    self.address.zip
  end
  
  def last_transaction
    raw["Last Trans Date"]
  end
  
  def dwelling_type
    raw["Type of Dwelling"]
  end

  def dwelling_class
    raw["Dwelling Classification"]
  end
  
  def year_built
    raw["Approx. Year Built"]
  end
  
  def num_of_images
    raw["# Images"]
  end
  
  def title_of_land
    raw["Title to Land"]
  end
  
  def broker
    raw["List Firm 1 Name"]
  end
  
  def link
    raw["Link"]
  end
  
  def date
    raw["Date"]
  end
  
  def title
    raw["Title"]
  end
  
  def extras=(text)
    write_attribute(:extras, white_list(text))
  end

  class << self
    def find_or_initialize_by_property(resource, klass, property, attributes={})
      fields = fields_for(resource, klass)
      key_name = RetsMetadata.find_key_name_for_resource(resource)
      returning(Listing.find_or_initialize_by_external_id(field_value_of(resource, fields, property, key_name))) do |listing|
        listing.rets_resource = resource
        listing.rets_class = klass
        listing.rets_property = property

        listing.attributes = attributes
        listing.raw_property_data = Hash[*property.map {|k, v| desc = fields.detect {|f| f.value == k}.description; [desc, 
            field_value_of(resource, fields, property, desc)]}.flatten]
        listing.mls_no = listing.raw("MLS Number")
  
        listing.description = [listing.raw("Public Remarks"), listing.raw("Public Remarks 2")].reject(&:blank?).join("")
  
        address = (listing.address || listing.build_address)
        address.line1 = listing.raw("Address")
        address.city = listing.raw("City")
        address.state = listing.raw("Province")
        address.zip = listing.raw("Postal Code")
  
        old_price = listing.price unless listing.new_record?
        listing.price = (listing.raw("List Price") || "").gsub(",", "").to_money
        unless listing.new_record? then
          listing.tag_list += " price-change" if listing.price != old_price && listing.tag_list["price-change"].nil?
        end
      end
    end

    def field_value_of(resource, fields, property, name)
      field = fields.detect {|f| name === f.description}
      return nil if field.blank?

      actual_value = property[field.value]
      if field.lookup_name.blank? then
        actual_value
      else
        values = Hash[*RetsMetadata.find_lookup_values(resource, field.lookup_name).flatten]
        values.invert[actual_value] || actual_value
      end
    end

    def fields_for(resource, klass)
      RetsMetadata.find_all_fields(resource, klass)
    end
  
    def find_all_by_area(area)
      self.find_tagged_with(:all => "#{area.gsub(' ', '-')}-area")
    end

    def import_remote_listings!(step_size=250)
      (0 .. 3000).step(step_size) do |low|
        high = low + step_size
        logger.info "Importing properties in the range: #{low .. high}"
        MlxchangeImporter.import_all(
            :base_uri => 'http://v14878.mlslink.mlxchange.com/',
            :price_range => (low .. high))
      end
    end
    
  end
  
  def interested_parties=(full_names)
    guys = full_names.split(";").collect{ |name| Party.find_by_full_name(name, :select => 'id') }.compact.map(&:id)
    Interest.delete_all("listing_id = #{self.id}") unless self.new_record?
    values = guys.collect{ |guy| self.interests.create(:party_id => guy)}
  end

  def dom_id(*extras)
    id = self.new_record? ? self.external_id : self.id
    [self.class.name.underscore, id, extras.map(&:to_s)].flatten.compact.join("_")
  end

  def import_pictures_from_mls!(seed_url)
    raise "No MLS No defined" if self.mls_no.blank?
    match = seed_url.match(/^(.*\/#{Regexp.escape(self.mls_no.downcase)})\d+(\.\w+)$/)
    raise "Unable to parse" unless match
    10.times do |index|
      index += 1
      uri = "#{match[1]}#{index}#{match[2]}"
      file_name = "#{self.mls_no.downcase}#{index}#{match[2]}"
      import_picture_from_uri!(uri, file_name)
    end

    logger.info "Imported #{self.views(true).count} pictures"
  end

  def import_picture_from_uri!(uri_location, filename=uri_location)
    uri = URI.parse(uri_location)
    logger.debug "Reading picture from #{uri.to_s.inspect}"
    begin
      picture = Picture.build_picture_from_image(Magick::Image.from_blob(uri.read).first)
      picture.attributes = {:filename => filename, :public => true}
      picture.account = self.account
      picture.save!

      self.views.create(:picture => picture)
    rescue OpenURI::HTTPError
      # 404 Not Found, most probably
      # We don't care and we try with the next picture
    end
  end

  def import_local_picture!(file)
    return unless file.size > 0
    begin
      file.rewind
      picture = Picture.build(file)
      picture.attributes = {:filename => file.original_filename, :public => true}
      picture.account = self.account
      picture.save!

      self.views.create!(:picture => picture)
    rescue
      logger.error "Unable to import #{file.inspect}:"
      logger.error $!.inspect
    end
  end
  
  def gmap_query
    raw_query = [raw["House #"], raw["Street Dir"], raw["Street Name"], raw['Street Type']].delete_if {|l| l.blank?}.join(" ")
    
    raw_query = raw_query.blank? ? [self.address.line1, self.address.line2, self.address.city, self.address.state, self.address.zip].delete_if {|l| l.blank?}.join(', ') : [raw_query, self.city, self.province, self.zip].delete_if {|l| l.blank?}.join(', ')
    raw_query.gsub(/#/, "")
  end

  def to_liquid
    ListingDrop.new(self)
  end
  
  def clean_duplicate_views
    uniq_asset_ids = self.views.map(&:asset_id).uniq
    uniq_asset_ids.each do |asset_id|      
      duplicates = self.views.find_all_by_asset_id(asset_id)[1..-1]
      duplicates.map(&:destroy) if !duplicates.blank?
    end
  end  

  def address_as_text
    self.address ? self.address.to_url : nil
  end
  
  def tags_as_text
    self.tags.map(&:name)
  end
  
  def copy_to(target)
    self.class.name.constantize.content_columns.map(&:name).each do |column|
      next if !target.send(column).blank?
      target.send("#{column}=", self.send(column))
    end
    target.tag_list = target.tag_list << " #{self.tag_list}"
    target.save!
    
    target.address = self.address.dup
    target.address.save!
  end
  
  def comment_approval_method
    if self.deactivate_commenting_on && (self.deactivate_commenting_on <= Date.today)
      return "no comments" 
    else
      self.read_attribute(:comment_approval_method)
    end
  end
  
  def send_comment_email_notification(comment)
    if self.creator && self.creator.confirmed? && self.creator.listing_comment_notification?
      AdminMailer.deliver_comment_notification(comment, "listing \"#{self.quick_description}\"", self.creator.main_email.email_address)
    end
  end
  
  protected
  
  def set_open_house_flag
    self.open_house = (self.open_house_text.blank? ? false : true)
    true
  end
  
  def set_open_house_text_to_nil_if_blank
    self.open_house_text = nil if self.open_house_text.blank?
  end

  def set_attributes_using_raw_data
    return if !self.new_record? && !self.overwrite_attributes
    self.status = self.raw["Status"] unless self.status
    self.region = self.raw["Area"] unless self.region
    self.area = self.raw["Sub-Area/Community"] unless self.area
    self.contact_email = self.raw["List Realtor 1 Email"] unless self.contact_email
    self.list_date = self.raw["List Date"] unless self.list_date
  end
  
  def set_default_attributes
    self.status = "Inactive" if self.status.blank?
    self.list_date = Time.now.utc.strftime("%Y-%m-%dT00:00:00") if self.list_date.blank?
    self.address = self.build_address unless self.address
  end
  
  def assign_raw_property_data
    write_attribute(:raw_property_data, @temp_raw_property_data) if @temp_raw_property_data
  end
  
  def destroy_files
    self.views.each do |view|
      if View.count(:all, :conditions => ["asset_id=?", view.asset_id]) == 0
        view.asset.destroy if view.asset
      end
    end
  end

  def copy_geolocation_from_address
    self.latitude, self.longitude = self.address.latitude, self.address.longitude
  end
end
