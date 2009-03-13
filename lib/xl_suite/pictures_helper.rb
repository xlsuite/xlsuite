#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module PicturesHelper
    def self.included(base)
      base.has_many :views, :as => :attachable, :order => "position", :dependent => :destroy
      base.has_many :assets, :through => :views
      base.has_many :pictures, :source => :asset, :through => :views, :order => "views.position", :conditions => 'assets.content_type LIKE "image/%"' 
      base.has_many :images, :source => :asset, :through => :views, :order => "views.position", :conditions => 'assets.content_type LIKE "image/%"' 
      base.after_save :update_image_ids
    end
  
    def picture_ids
      @image_ids || self.class.connection.select_values(%Q~SELECT assets.id FROM assets INNER JOIN views ON assets.id = views.asset_id WHERE ((views.attachable_type = '#{self.class.name}') AND (views.attachable_id = #{self.id})) ORDER BY views.position~)
    end
    alias_method :image_ids, :picture_ids
        
    def image_ids=(asset_ids)
      raise "image_ids= only takes in an array" unless asset_ids.kind_of?(Array)
      @image_ids = asset_ids
    end
    alias_method :picture_ids=, :image_ids=

    def set_main_image(image_id)
      image_id_clone = if image_id.kind_of?(Fixnum)
          image_id
        else
          image_id.respond_to?(:clone) ? image_id.clone.to_i : image_id.to_i
        end
      image = self.account.assets.find(image_id_clone)
      object_view = self.views.find(:first, :conditions => ["views.asset_id = ?", image_id_clone])
      if object_view
        object_view.move_to_top
      else
        self.assets << image
        object_view = self.views.find(:first, :order => "position DESC")
        object_view.move_to_top
      end
      object_view
      rescue ActiveRecord::RecordNotFound
        return nil
    end
    
    alias_method :main_image=, :set_main_image
    
    def main_image_id
      object_view = self.views.find(:first, :order => "position ASC")
      return nil unless object_view
      return object_view.asset_id
    end
  
    alias_method :main_image, :main_image_id
    
    def update_image_ids
      return unless @image_ids
      self.class.transaction do
        self.views.each do |view|
          asset = view.asset
          view.destroy if asset.content_type =~ /^image/i
        end
        @image_ids.each do |asset_id|
          asset = self.account.assets.find(asset_id)
          self.views.create(:asset => asset) if asset.content_type =~ /^image/i
        end
      end
    end
    protected :update_image_ids    
    
  end
end
