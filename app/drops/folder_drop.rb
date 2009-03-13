#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FolderDrop < Liquid::Drop
  attr_reader :folder
  delegate :id, :total_size, :name, :updated_at, :owner, :description, :created_at, :private, :assets, 
           :children, :to => :folder
  
  def initialize(folder)
    @folder = folder
  end

  def folder_path
    (self.ancestors.map(&:name)).join("/")
  end
end
