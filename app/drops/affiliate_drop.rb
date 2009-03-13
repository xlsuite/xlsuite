#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AffiliateDrop < Liquid::Drop
  delegate :id, :target_url, :source_url, :party, :created_at, :updated_at, :to => :affilate
  attr_reader :affilate

  def initialize(affilate=nil)
    @affilate = affilate
  end
end
