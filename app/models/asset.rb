#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "action_view/helpers/number_helper"
require "action_view/helpers/text_helper"
require "action_view/helpers/url_helper"
require "open-uri"
require "digest/md5"

class Asset < ActiveRecord::Base
  include XlSuite::AccessRestrictions
  include XlSuite::PicturesHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

  include CacheControl
  def http_headers
    returning(self.cache_control_headers) do |headers|
      headers["Etag"] = self.etag if self.etag
      headers.merge(
        CacheControl.cache_control_headers(
            :updated_at => self.updated_at,
            :cache_timeout_in_seconds => 10.years.to_i,
            :cache_control_directive => "public"))
    end
  end
  
  # Please modify View#set_classification if the following conditions are changed
  IMAGE_FILES_CONDITION = "(assets.content_type LIKE 'image/%')"
  AUDIO_FILES_CONDITION = "(assets.content_type LIKE 'audio/%')"
  VIDEO_FILES_CONDITION = "(assets.content_type LIKE 'video/%')"
  SHOCKWAVE_FILES_CONDITION = "(assets.content_type LIKE '%shockwave%')"
  FLASH_FILES_CONDITION = "(assets.filename LIKE '%.flv')"
  MULTIMEDIA_CONDITIONS = "#{VIDEO_FILES_CONDITION} OR #{SHOCKWAVE_FILES_CONDITION} OR #{FLASH_FILES_CONDITION} OR #{AUDIO_FILES_CONDITION}"
  OTHER_FILES_CONDITIONS = "NOT (#{IMAGE_FILES_CONDITION} OR #{MULTIMEDIA_CONDITIONS})"

  THUMBNAIL_SIZES = {:square => "75x75!", :mini => "100x>", :small => "240x>", :medium => "500x>"}
  
  belongs_to :folder
  belongs_to :account
  belongs_to :parent_asset, :class_name => "Asset", :foreign_key => "archive_id"
  has_many :asset_children, :class_name => "Asset", :foreign_key => "archive_id", :dependent => :nullify
  validates_presence_of :account_id, :if => lambda {|r| r.parent.blank?}

  has_many :parent_objects, :class_name => "View", :dependent => :destroy

  belongs_to :owner, :class_name => "Party", :foreign_key => :owner_id

  attr_accessor :external_url
  validates_format_of :external_url, :with => %r{\A(?:ftp|https?)://.*\Z}i, :allow_nil => true, :message => "must be absolute url", :if => :external_url_not_blank
  before_validation :assign_external_url_data_to_temp_data

  acts_as_taggable
  acts_as_fulltext %w(filename title content_type description folder_name tag_list)
  has_attachment :max_size => 1.gigabyte, :min_size => 0, :storage => :file_system
  belongs_to :parent, :class_name => "Asset", :foreign_key => :parent_id
  validates_as_attachment

  before_validation :ensure_unique_filename
  validates_uniqueness_of :filename, :scope => [:account_id, :folder_id], :if => lambda {|r| r.parent.blank?}
  before_save :set_account_to_parent_account
  before_save :calculate_cache_directives
  before_validation :set_content_type_if_missing
  
  before_save :ensure_asset_size_caps_not_exceeded
  before_save :generate_etag
  after_create :update_parent_timestamps
  after_create :increase_current_total_asset_size
  after_destroy :update_parent_timestamps
  after_destroy :decrease_current_total_asset_size
  before_update :set_old_size
  after_update :update_current_total_asset_size
  after_update :update_parent_timestamps
  before_save :get_old_folder_id
  after_save :update_old_folder_timestamps
  after_save :unpack_zip_archives
  after_save :create_thumbnails
  
  before_create :generate_random_uuid

  has_many :authorizations, :class_name => 'AssetAuthorization', :order => 'created_at'

  attr_accessor :zip_file
  def zip_file?; @zip_file == "1" || @zip_file == 1; end

  attr_accessor :private_changed
  after_save :set_storage_access, :if => lambda{|r| r.private_changed}

  def src
    self.private ? self.authenticated_s3_url : self.s3_url
  end
  
  def z_src
    path = []
    if self.folder
      path += self.folder.self_and_ancestors.map{|e| url_encode(e.name)}
    end
    path << url_encode(self.filename)
    "/z/" + path.join("/")
  end
  
  def create_thumbnails
    return unless self.thumbnailable?
    MethodCallbackFuture.create!(:models => [self], :account =>  self.account, :method => :generate_thumbnails, :priority => 150) unless self.blank?
  end

  def generate_thumbnails
    temp_file = self.create_temp_file
    Asset::THUMBNAIL_SIZES.each { |suffix, size| create_or_update_thumbnail(temp_file, suffix, *size) }
  end

  def self.find_users_files(user_ids, current_account, limit=10)
    user_ids_arr = []
    user_ids.split(',').each{|id| user_ids_arr << id.to_i} unless user_ids.blank?
    current_account.assets.find(:all, :conditions => ["owner_id IN (?)", user_ids_arr], :limit => limit)
  end
  
  def file_directory_path
    path = self.folder ? self.folder.self_and_ancestors.map(&:name).join('/')+"/" : ""
    path << self.filename
  end
  
  def self.find_readable_by(party, query_params, search_options, additional_conditions)
    group_ids = party.groups.find(:all, :select => "groups.id").map(&:id)
    conditions = "permission_sets.id IS NULL"
    conditions << " OR permission_sets.id IN (#{group_ids.join(',')})" unless group_ids.blank?
    asset_ids = self.find(:all, :select => "#{self.table_name}.id",
      :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="#{self.name}" AND authorizations.object_id=#{self.table_name}.#{self.primary_key}`, 
          %Q`LEFT JOIN permission_sets ON permission_sets.type="Group" AND permission_sets.id=authorizations.group_id`].join(" "), 
      :conditions => conditions ).map(&:id)
    return [] if asset_ids.blank?
    self.search(query_params, search_options.merge(:conditions => "#{self.table_name}.#{self.primary_key} IN (#{asset_ids.join(",")}) AND #{additional_conditions}"))
  end
  
  def self.count_readable_by(party, query_params, additional_conditions)
    group_ids = party.groups.find(:all, :select => "groups.id").map(&:id)
    conditions = "permission_sets.id IS NULL"
    conditions << " OR permission_sets.id IN (#{group_ids.join(',')})" unless group_ids.blank?
    asset_ids = self.find(:all, :select => "#{self.table_name}.id",
      :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="#{self.name}" AND authorizations.object_id=#{self.table_name}.#{self.primary_key}`, 
          %Q`LEFT JOIN permission_sets ON permission_sets.type="Group" AND permission_sets.id=authorizations.group_id`].join(" "), 
      :conditions => conditions).map(&:id)
    count_options = nil
    return 0 if asset_ids.blank?
    if query_params.blank?
      count_options = {:conditions => "#{self.table_name}.#{self.primary_key} IN (#{asset_ids.join(",")}) AND #{additional_conditions}"}
    else
      count_options = {:conditions => "subject_type='#{self.name}' AND subject_id IN (#{asset_ids.join(",")}) AND #{additional_conditions}"}
    end
    self.count_results(query_params, count_options)
  end

  def label
    return self.title unless self.title.blank?
    self.filename
  end
  
  def after_moved_from_folder(previous_folder_id)
    update_parent_timestamps(previous_folder_id)
  end

  def downloads_count
    self.authorizations.sum(:download_count) || 0
  end

  def owner_name
    self.owner ? self.owner.display_name : nil
  end

  def geometry(size=nil)
    t = size ? find_or_initialize_thumbnail(size) : self
    [t.width, t.height] * "x"
  end

  def crop_resized(geometry)
    with_image do |img|
      img2 = img.crop_resized(*geometry.split("x").map(&:to_i))
      self.temp_data = img2.to_blob
    end
  end

  def icon
    :page_white
  end

  # Is this file a ZIP archive ?
  def zip?
    %w(application/zip application/x-zip).include?(self.content_type) || self.filename =~ /\.zip\Z/
  end
  
  def file_extension
    return "" unless self.filename.match(/\.([\d\w]+)$/i)
    $1.downcase
  end
  
  def shockwave_file?
    match_data = /shockwave/i.match(self.content_type)
    return true if match_data
    nil
  end
  
  def audio_file?
    match_data = /^audio\//i.match(self.content_type)
    return true if match_data
    nil
  end

  %w(mp3 flv).each do |file_type|
    class_eval <<-EOF
      def #{file_type}_file?
        return true if self.file_extension == "#{file_type}"
        nil
      end
    EOF
  end
  alias_method :flash_file?, :flv_file?
    
  def unzip
    raise "Not a ZIP file" unless self.zip?
    returning File.join(Dir.tmpdir, "tmp", Process.pid.to_s, rand().to_s) do |root|
      Tempfile.open(self.filename) do |zipfile|
        begin
          logger.debug {"==> Copying zip file to #{zipfile.path}"}
          zipfile.write(current_data)
          zipfile.rewind
          logger.debug {"==> zipfile is #{zipfile.length} bytes in length"}
          Zip::Archive.new(zipfile.path).unzip_to(root)
        rescue Object, Exception
          logger.error "Could not unzip file:"
          logger.error $!.message
          logger.error $!.backtrace.join("\n")
          raise
        end
      end
    end
  end

  # Unpacks this archive and adds all files as assets that are children of this one.
  def unpack_archive
    returning [] do |assets|
      begin
        dir = self.unzip
        transaction do
          Dir[File.join(dir, "**", "*")].each do |path|
            next if File.directory?(path)
            logger.debug {"Adding unpacked #{path.inspect} to assets"}
            assets << asset = self.account.assets.create!(:parent_asset => self,
                :temp_data => File.open(path, "rb") {|f| f.read},
                :owner => self.owner,
                :reader_ids => self.reader_ids, :writer_ids => self.writer_ids,
                :folder_id => self.folder_id, :filename => File.basename(path))
          end
        end
      rescue
        logger.error {"==> Error unzipping file:\n#{$!}\n#{$!.backtrace.join("\n")}"}
      ensure
        FileUtils.rm_rf(dir) rescue nil
      end
    end
  end

  def guess_content_type
    filepath = self.new_record? ? self.temp_path : self.full_filename
    type = `/usr/bin/file --mime --brief --preserve-date #{filepath}`
    ($? && $?.success?) ? type.chomp : "application/octet-stream"
  end

  def to_liquid
    AssetDrop.new(self)
  end

  def image_url(size=nil)
    returning %Q(/admin/assets/#{id}/download) do |url|
      url << "?size=#{size}" unless size.blank?
    end
  end

  def to_json(url="/admin/assets/__ID__/download")
    url_temp = url.gsub("__ID__", self.id.to_s)
    thumbnail_url = "/images/icons/text_thumb.jpg"
    if self.content_type =~ /^image/i
      thumbnail_url = url_temp.clone 
      thumbnail_url << "?size=mini" if self.thumbnails.find_by_thumbnail("mini")
    end
    link = url_temp
    %Q!{'id':'#{self.dom_id}',\
      'real_id':'#{e(self.id.to_s)}',\ 
      'label':'#{e(self.filename)}',\ 
      'type':'#{e(self.content_type)}',\ 
      'size':'#{e(number_to_human_size(self.size))}',\
      'path':'#{e(link)}',\
      'z_path':'#{e("/z/"+self.file_directory_path)}',\
      'folder':'#{e(self.folder_name)}',\ 
      'folder_id':'#{(self.folder ? self.folder.id : 0)}',\ 
      'url':'#{e(thumbnail_url)}',\
      'notes':'#{e(self.description)}',\
      'tags':'#{e(self.tag_list)}',\
      'absolute_path':'#{e(self.src)}',\
      'created_at':'#{e(self.created_at.strftime(ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:iso]))}',\
      'updated_at':'#{e(self.updated_at.strftime(ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:iso]))}'\
      }!
  end
  
  def z_path
    "/z/" + self.file_directory_path
  end
  
  def path(default_path="/admin/assets/__ID__/download")
    default_path.gsub("__ID__", self.id.to_s)
  end
  
  def thumbnail_path
    url = "/images/icons/text_thumb.jpg"
    if self.content_type =~ /^image/i
      url = self.path
      url << "?size=mini" if self.thumbnails.find_by_thumbnail("mini")
    end
    url
  end
  
  def humanized_size
    self.number_to_human_size(self.size)
  end
    
  def attributes_for_copy_to(account)
    self.attributes.dup.merge(:account_id => nil, :account => account, :tag_list => self.tag_list, 
                              :owner => account.owner, :temp_data => self.read_data, :folder_id => nil)
  end

  def temp_data=(data)
    self.set_temp_data(data)
  end
  
  def read_data
    errored = 0
    begin
      File.open(self.create_temp_file.path, "rb"){|f|f.read}
    rescue
      errored += 1
      retry if errored < 3
      raise # 3 strikes - you're out!
    end
  end

  def private=(value)
    @private_changed = (private != value) || @private_changed
    write_attribute :private, value
  end
  
  class << self
    def find_all_parents(options={})
      with_scope(:find => {:conditions => {:parent_id => nil}}) do
        find(:all, options.reverse_merge(:order => "title"))
      end
    end

    def get_titled_like(title)
      find(:all, :conditions => ["title LIKE :q OR filename LIKE :q AND parent_id IS NULL", {:q => "%#{title}%"}])
    end

    def get_tagged_with(tag_list, options={})
      with_scope(:find => {:conditions => "parent_id IS NULL"}) do
        find_tagged_with(options.merge(:all => tag_list))
      end
    end
    
    def find_by_path_and_filename(path, filename)
      assets = find_all_by_filename(filename)
      return nil if assets.blank?
      
      assets.each do |asset|
        object = asset.folder
        if path.blank?
          object ? next : (return asset)
        else
          next if object.blank?
        end
        path_array = path.split('/')
        next_asset = false
        (path_array.size-1).downto(0) do |i|
          if object.name.downcase != path_array[i].downcase
            #processing on this asset is done, do next asset
            next_asset = true
            
            #break out of this for loop
            break 
          end
          object = object.parent
        end
        next_asset ? next : (return asset)
      end
      return nil
    end
  end

  def folder_name
    self.folder ? self.folder.name : "Root"
  end
  
  def public?
    !self.private
  end
  
  def private?
    self.private
  end
  
  def readable_by?(party)
    return true if self.new_record?
    return true if self.owner_id == party.id if party
    if self.public?
      return true if self.readers.empty?
      return false unless party
      return (self.readers + self.writers).uniq.any? do |group|
        party.member_of?(group)
      end
    else
      return false unless party
      return true if party.granted_assets.map(&:id).include?(self.id)
      expiring_item = party.expiring_items.find(:first, :conditions => ["item_type=? AND item_id=? AND (expired_at IS NULL OR expired_at > ?)", "Asset", self.id, Time.now.utc])
      return !expiring_item.nil?
    end
  end  

  def self.count_with_overwritten(*args)
    unless args.blank?
      self.count_without_overwritten(*args)
    else
      Asset.count_by_sql "SELECT COUNT(a.id) FROM assets a"
    end
  end
  class <<self
    alias_method_chain :count, :overwritten
  end

  protected
  def set_account_to_parent_account
    self.account = self.parent.account unless self.account || !self.parent
  end

  def set_content_type_if_missing
    return unless self.content_type.blank?
    self.content_type = self.guess_content_type
  end
  
  def update_parent_timestamps(folder_id=nil)
    p = if folder_id
      Folder.find(folder_id)
    else
      self.folder
    end
    p.update_attribute(:updated_at, Time.now) if p
  end
  
  def get_old_folder_id
    @old_folder_id = self.folder_id
  end
  
  def update_old_folder_timestamps
    self.update_parent_timestamps(@old_folder_id)
  end

  def filename_already_used?(fname)
    aid = self.account ? self.account.id : self.account_id
    fid = self.folder ? self.folder.id : self.folder_id
    !!self.class.find(:first, :select => "id", :conditions => {:account_id => aid, :folder_id => fid, :filename => fname})
  end

  # Only do this validation if on a new record.
  def ensure_unique_filename
    return true unless self.new_record?
    return true unless self.filename_already_used?(self.filename)
    parts = self.filename.split(".")
    basename, extension = parts[0..-2].join("."), parts.last
    case basename
    when /-(\d+)$/ # We already modified this filename, start at the next number
      basename.sub!(/-(\d+)$/, "")
      initial = $1.to_i.succ
    else # New filename
      initial = 1
    end

    candidate_filename = (initial .. initial + 40).detect do |index|
      fname = "#{basename}-#{index}.#{extension}"
      break fname unless self.filename_already_used?(fname)
    end

    raise ArgumentError, "Bad filename: #{candidate_filename.inspect}" if candidate_filename.blank?
    self.filename = candidate_filename
  end

  def unpack_zip_archives
    return unless self.zip_file?
    self.asset_children.destroy_all unless self.new_record?
    MethodCallbackFuture.create!(:models => [self], :account =>  self.account, :method => :unpack_archive, :priority => 50)
  end
  
  def external_url_not_blank
    !self.external_url.blank?    
  end
  
  def assign_external_url_data_to_temp_data
    return if self.external_url.blank?
    begin
      external_url_data = open(self.external_url)
      self.temp_data = external_url_data.read
      self.content_type = external_url_data.content_type
      filename = self.external_url.split("/").last
      filename = external_url_data.path if filename.blank?
      self.filename = File.basename(filename)
    rescue
      logger.warn {"==> Could not open #{self.external_url}: #{$!.message}"}
      false
    end
  end

  # See: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
  # for the full, excruciating, details of how/why these numbers are here
  def calculate_cache_directives
    self.cache_timeout_in_seconds = 2.hours

    # If the asset has no access restrictions, we can tell the proxies/caches to cache the file publicly
    # Else, it has to not be stored by anybody but the end-user's cache
    self.cache_control_directive = readers.empty? && writers.empty? ? "public" : "private"
  end

  def generate_etag
    self.etag = Digest::MD5.hexdigest(self.temp_data) if self.temp_data
  end

  def generate_etag_from_current_data
    self.update_attribute(:etag, Digest::MD5.hexdigest(current_data))
  end
  
  def increase_current_total_asset_size
    Account.connection.execute("UPDATE accounts SET current_total_asset_size = current_total_asset_size + #{self.size} WHERE id=#{self.account.id}")
  end
  
  def decrease_current_total_asset_size
    Account.connection.execute("UPDATE accounts SET current_total_asset_size = current_total_asset_size - #{self.size} WHERE id=#{self.account.id}")
  end
  
  def set_old_size
    self.instance_variable_set(:@_old_size, self.size)
  end
  
  def update_current_total_asset_size
    old_size = self.instance_variable_get(:@_old_size)
    Account.connection.execute("UPDATE accounts SET current_total_asset_size = current_total_asset_size + #{self.size - old_size} WHERE id=#{self.account.id}")
  end
  
  def ensure_asset_size_caps_not_exceeded
    if self.account.cap_asset_size < self.size
      self.errors.add_to_base("File size #{number_to_human_size(self.account.cap_asset_size)} limit exceeded.")
      return false
    end
    if self.account.cap_total_asset_size < (self.account.current_total_asset_size + self.size)
      self.errors.add_to_base("Account storage size #{number_to_human_size(self.account.cap_total_asset_size)} limit exceeded.")
      return false
    end
  end
end
