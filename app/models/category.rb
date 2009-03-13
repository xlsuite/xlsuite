#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Category < ActiveRecord::Base
  acts_as_taggable
  
  has_many :categorizables
  has_many :account_templates, :through => :categorizables, :source => :subject, :source_type => "AccountTemplate"
  has_many :children, :through => :categorizables, :source => :subject, :source_type => "Category"
  
  belongs_to :account
  belongs_to :avatar, :class_name => "Asset"

  validates_presence_of :account_id, :name, :label
  validates_uniqueness_of :label, :scope => [:account_id]
  validates_format_of :label, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)"
  
  before_validation :set_name
  
  attr_accessor :parent_id, :parent
  after_save :set_parent_relation
  
  def self.find_all_roots(from_acct)
    non_root_category_ids = Categorizable.find(:all, :select => "categorizables.subject_id", :conditions => {:subject_type => "Category"}).map(&:subject_id).uniq
    non_root_category_ids = [0] if non_root_category_ids.empty?
    from_acct.categories.all(:order => "name ASC", :conditions => ["id NOT IN (?)", non_root_category_ids])
  end
  
  protected
  
  def set_parent_relation
    return unless self.parent_id || (self.parent && self.parent.kind_of?(Category))
    parent_candidate = self.parent
    if self.parent_id
      parent_candidate = self.account.categories.find(self.parent_id.to_i)
    end
    raise "Failed in setting up parent relation of category" unless parent_candidate
    parent_relation = parent_candidate.categorizables.create!(:subject => self)
  end
  
  def set_name
    self.name = self.label if self.name.blank?
  end
end
