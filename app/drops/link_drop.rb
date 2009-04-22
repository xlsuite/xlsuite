#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class LinkDrop < Liquid::Drop
  attr_reader :link
  delegate :title, :url, :description, :active_at, :inactive_at, :approved, :created_at, 
           :assets, :pictures, :id, :to => :link

  def initialize(link)
    @link = link
  end
  
  def picture_url
    self.link.pictures ? "/admin/assets/#{link.pictures.first.id}/download?size=square" : "/images/no-image_small.jpg"
  end
  
  def main_picture
    self.link.pictures.empty? ? nil : AssetDrop.new(self.link.pictures.first)
  end
end
