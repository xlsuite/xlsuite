#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TagDrop < Liquid::Drop
  attr_reader :tag
  delegate :id, :name, :products, :to => :tag
  
  def initialize(tag)
    @tag = tag
  end
end
