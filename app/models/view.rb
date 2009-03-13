#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class View < ActiveRecord::Base
  acts_as_list :scope => 'attachable_type = \"#{attachable_type}\" AND attachable_id = #{attachable_id} AND classification = \"#{classification}\"'
  validates_presence_of :asset_id
  validates_uniqueness_of :asset_id, :scope => [:attachable_type, :attachable_id]

  belongs_to :attachable, :polymorphic => true
  belongs_to :asset

  before_validation :set_classification
  validates_presence_of :classification

  protected
  def set_classification
    self.classification = case asset.content_type
      when /^image/i
        "image"
      when /^audio/i
        "multimedia"
      when /^video/i
        "multimedia"
      when /shockwave/i
        "multimedia"
      when /flv$/i
      else
        "other_files"
      end
  end
end
