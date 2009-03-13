#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Permission < ActiveRecord::Base
  before_validation :normalize_name
  validates_length_of :name, :within => 1..80

  def self.find_or_create(name)
    name = self.normalize(name)
    self.find_by_name(name) || self.create(:name => name)
  end

  def self.all
    self.find(:all, :order => 'name')
  end

  def self.normalize(name)
    name.to_s.underscore
  end

  def to_formatted_s
    self.to_s.humanize.titleize
  end

  def to_s
    self.name
  end
  
protected
 def normalize_name
  self.name = self.class.normalize(self.name)
 end
end
