#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SearchLine < ActiveRecord::Base
  belongs_to :search
  validates_uniqueness_of :priority, :scope => [:search_id]
  
  def to_hash
    hash = { :subject_name => self.subject_name, :subject_option => self.subject_option, :subject_value => self.subject_value }
    hash.merge({:subject_exclude => "1"}) unless self.subject_exclude.blank?
    return hash
  end
end
