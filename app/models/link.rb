#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'net/http'
require 'uri'

class Link < ActiveRecord::Base
  include XlSuite::PicturesHelper
  
  attr_protected :approved

  acts_as_taggable
  acts_as_fulltext %w(title url categories_as_text description tags_as_text)

  has_and_belongs_to_many :link_categories
  belongs_to :account
  
  before_validation :normalize_url
  
  validates_presence_of :title, :url, :account_id
  validates_format_of :url, :with => %r{\A(?:ftp|https?)://.*\Z}

  def to_liquid
    LinkDrop.new(self)
  end

  def self.find_for_public
    conditions = []
    values = []

    conditions << '(active_at IS NULL OR active_at <= ?)'
    values << Date.today

    conditions << '(inactive_at IS NULL OR inactive_at > ?)'
    values << Date.today
    
    conditions << '(approved = true)'
    
    self.find(:all, :order => 'title',
        :conditions => [conditions.join(' AND '), *values])
  end
  
  # Implement periodic link checker using rails_cron
  # Links will be checked every two days and inactive links will be removed
  def self.remove_inactive_links
    Link.find(:all).each do |link|
      begin
        response = Net::HTTP.get_response(URI.parse(link.url))
        if (response==Net::HTTPServerError || response==Net::HTTPClientError)
          link.destroy
        end
      rescue
        link.destroy
      end
    end
  end
    
  def self.find_all_approved(options={})
    with_scope(:find => {:conditions => ['approved = true']}) do
      self.find(:all, options)
    end
  end

  def self.find_all_unapproved(options={})
    with_scope(:find => {:conditions => ['approved = false']}) do
      self.find(:all, options)
    end
  end

  def category_ids=(values)
    self.link_categories.clear
    return if values.blank?
    values = values.to_s.split(',').uniq.compact
    self.link_categories << LinkCategory.find(values)    
  end
  
  def main_identifier
    "#{self.title} : #{self.url}"
  end  
  
  def tags_as_text
    self.tags.map(&:name)
  end
  
  def attributes_for_copy_to(account)
    self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :tag_list => self.tag_list)
  end
  
  def copy_assets_from!(link)
    unless link.assets.blank?
      link.assets.each do |asset|
        full_path = asset.file_directory_path.split("/")
        name = full_path.pop
        path = full_path.join("/")
        existing_asset = self.account.assets.find_by_path_and_filename(path, name)
        existing_asset = self.account.assets.create(asset.attributes_for_copy_to(self.account)) unless existing_asset
        
        unless self.views.map(&:asset_id).include?(existing_asset.id)
          view = self.views.build(:asset_id => existing_asset.reload.id)
          view.classification = "Image"
          view.save!
        end
      end
    end
  end
protected
  def normalize_url
    return if self.url.blank?
    return if self.url =~ %r{^(?:ftp|https?)://}
    self.url = "http://#{self.url}"
  end

  def categories_as_text
    self.link_categories.map(&:name)
  end
end
