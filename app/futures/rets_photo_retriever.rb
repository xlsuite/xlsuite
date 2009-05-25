#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RetsPhotoRetriever < RetsFuture
  validate :args_must_contain_key_named_key
  validate :args_must_contain_listing_id
  validates_presence_of :account_id

  def run_rets(rets)
    logger.info {"==> Running RETS GetObject:#{self.id}"}
    self.results = {:picture_ids => []}
    original_progress = self.progress

    listing = self.account.listings.find(args[:listing_id])
    folder = self.account.folders.find(:first, :conditions => {:parent_id => nil, :name => "rets_import_pictures"})
    unless folder
      folder = self.account.folders.build(:name => "rets_import_pictures", :description => "Directory containing pictures from all RETS import")
      folder.save!
    end
    rets.get_photos(:property, "#{self.args[:key]}") do |data, options|
      logger.info {"==> \#get_photos(__binary data__, #{options.inspect})"}
      status!(:reading, original_progress + 3*self.results.size)
      next if options['Content-ID'].blank?
      filename = "#{options['Content-ID']}-#{options['Object-ID']}.jpg"

      asset = self.account.assets.find_or_initialize_by_filename(filename)
      unless asset.new_record?
        logger.info {"==> Asset with name #{filename.inspect} already exists"}
        next
      end
      asset.content_type = options["Content-Type"]
      asset.temp_data = data
      asset.account = self.account
      asset.tag_list = self.args[:tags] unless self.args[:tags].blank?
      asset.folder_id = folder.id
      asset.save!

      listing.views.create(:asset => asset)
      self.results[:picture_ids] << asset.id
    end
  end

  def photos
    Asset.find(self.results[:picture_ids])
  end

  protected
  def args_must_contain_key_named_key
    self.errors.add_to_base("args does not contain an entry named :key") unless self.args.has_key?(:key)
  end

  def args_must_contain_listing_id
    self.errors.add_to_base("args does not contain have a :listing_id reference") unless self.args.has_key?(:listing_id)
  end
end
