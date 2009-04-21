#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# The model for link categories
class LinkCategory < ActiveRecord::Base
  acts_as_tree :order => 'name'

  has_and_belongs_to_many :links
  
  validates_presence_of :name, :account_id
  validates_uniqueness_of :name, :scope => :parent_id
  validates_length_of :name, :maximum => 50
  validates_length_of :description, :maximum => 200, :allow_nil => true

  before_destroy :root_check

  def self.find_the_root
    self.find(:first, :conditions => "parent_id IS NULL")
  end
  
  def main_identifier
   "#{self.name} - link category"
  end  
protected  
  def root_check
    if LinkCategory.find_the_root.id == self.id
      raise "ERROR: Not allowed to destroy root"
      return
    end
    move_children_to_parent
  end
  
  def move_children_to_parent
    for child in self.children
      clone_id = child.id
      clone_name = child.name
      clone_description = child.description
      child.destroy
      clone = LinkCategory.new()
      clone.id = clone_id
      clone.name = clone_name      
      clone.description = clone_description
      clone.save
      clone.parent = self.parent
      clone.save
    end
  end
  
end
