#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "action_view/helpers/number_helper"

class Folder < ActiveRecord::Base
  include XlSuite::AccessRestrictions
  include ActionView::Helpers::NumberHelper

  acts_as_taggable
  acts_as_nested_set        :order => "name"
  has_many                  :assets, :dependent => :destroy, :order => "filename"
  belongs_to                :account
  validates_presence_of     :account_id
  
  belongs_to :owner, :class_name => "Party", :foreign_key => :owner_id
    
  validates_presence_of     :name
  validates_uniqueness_of   :name, :scope => [:parent_id, :account_id]
  validates_length_of       :name, :maximum => 254, :allow_nil => true
  
  before_create :generate_random_uuid
  before_validation :move_to_child_of_with_overwritten
  before_save :inherit_attributes
  after_save :update_parent_timestamps, :update_child_attributes 
  after_destroy :update_parent_timestamps
  
  attr_accessor :par_id, :do_not_update_parent_timestamps

  def viewable_by?(party)
    return false if self.private && party.id != self.owner_id
    self.readable_by?(party)
  end
  
  def editable_by?(party)
    return false if self.private && party.id != self.owner_id
    self.writeable_by?(party)
  end
  
  def total_size
    sum = 0
    assets_sum = Asset.sum(:size, :conditions => ["folder_id IN (?)", self.all_children] ) unless self.all_children.blank?
    sum += assets_sum if assets_sum
    sum += self.assets.sum(:size) unless self.assets.blank?
    sum
  end
  
  def self.create_fake_folder
    @folder = {:id => 0, :parent_id => :false}
  end
 
  def move_to_child_of_with_overwritten
    self.class.transaction do
      par_id = self.par_id
      self.par_id = nil
      self.save_without_validation
      if par_id.blank?
        self.move_to_right_of(self.ancestors.first) if self.ancestors.first
      else
        self.move_to_child_of_without_overwritten(par_id)
      end
    end
  end
  alias_method_chain :move_to_child_of, :overwritten
  
  def update_tags
    if self.parent && (self.inherit || self.parent.pass_on_attr)
      self.update_attributes!(:tag_list => self.tag_list + "," + self.parent.tag_list)
    end
  end
  
  def to_json
    %Q!{'id':'#{self.dom_id}',\
      'label':'#{e(self.name)}',\ 
      'type':'folder',\ 
      'size':'#{e(number_to_human_size(self.total_size))}',\
      'folder':'#{e(self.parent_folder_name)}',\
      'path':'#{e(self.path)}',\
      'url':'#{e("/images/icons/folder_thumb.jpg")}',\
      'notes':'#{e(self.description)}',\
      'tags':'#{e(self.tag_list)}',\
      'created_at':'#{e(self.created_at.strftime(ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:iso]))}',\
      'updated_at':'#{e(self.updated_at.strftime(ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:iso]))}'\
      }!
  end

  def self.find_by_path(path)    
    path_array = path.split('/')
    folders = self.find_all_by_name(path_array.pop)
    return nil if folders.blank?
    folders.each do |folder|
      object = folder
      next_folder = false
      skip_each_loop = false
      (path_array.size-1).downto(0) do |i|
        object = object.parent
        
        #process next folder if parent not found
        if !object
          next_folder = true
          break
        end
        
        if object.name.downcase != path_array[i].downcase
          #processing on this folder is done, do next folder
          next_folder = true
          
          #break out of this for loop
          break 
        end
      end unless path_array.blank?
      next_folder ? next : (return folder)
    end
    return nil
  end
  
  def parent_folder_name
    self.parent ? self.parent.name : "Root"
  end

  def path
    (["Root"] + self.ancestors.map(&:name)).join("/") + "/"
  end
  
  def attributes_for_copy_to(account)
    account_owner_id = account.owner ?  account.owner.id : nil
    self.attributes.dup.merge(:account_id => account.id, :tag_list => self.tag_list, 
                              :owner_id => account_owner_id, :lft => nil, :rgt => nil, :parent_id => nil)
  end
  
  def copy_assets_and_subfolders_from_folder!(source_folder)
    #copy old folder assets into new folder
    source_folder.assets.each do |asset|
      new_asset = self.account.assets.build(asset.attributes_for_copy_to(self.account))        
      new_asset.folder_id = self.id
      new_asset.save!
    end
    #copy old subfolders and their assets into new folder
    source_folder.children.each do |subfolder|
      new_folder = self.account.folders.build(subfolder.attributes_for_copy_to(self.account))
      new_folder.par_id = self.id
      new_folder.save!
      new_folder.copy_assets_and_subfolders_from_folder!(subfolder)
    end
  end

  def to_liquid
    FolderDrop.new(self)
  end
  
protected
  def update_parent_timestamps
    unless self.do_not_update_parent_timestamps
      p = self.class.find_by_id(self.parent_id)
      return unless p
      if p
        p.reader_ids = p.reader_ids
        p.writer_ids = p.writer_ids
        p.update_attribute(:updated_at, Time.now) 
      end
    end
  end
  
  def inherit_attributes
    if self.parent && self.inherit
      self.tag_list = self.parent.tag_list + ", " + self.tag_list
      self.reader_ids = self.parent.reader_ids
      self.writer_ids = self.parent.writer_ids
      self.private = self.parent.private
    end
  end
  
  def update_child_attributes
    if self.children
      if self.pass_on_attr
        pass_on_attributes_to_children
      else
        self.children.each do |child| 
          if child.inherit
            child.inherit_attributes
            child.do_not_update_parent_timestamps = true
            child.save
            child.do_not_update_parent_timestamps = false
          end
        end
      end
    end
  end
  
  def pass_on_attributes_to_children
    self.children.each do |child|
      child.tag_list = self.tag_list + ", " + child.tag_list
      child.reader_ids = self.reader_ids
      child.writer_ids = self.writer_ids
      child.private = self.private
      child.do_not_update_parent_timestamps = true
      child.save
      child.do_not_update_parent_timestamps = false
    end
  end
end
