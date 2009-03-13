#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class OpenStructDrop < Liquid::Drop
  attr_reader :object

  def initialize(object)
    @object = object
  end

  def before_method(name)
    self.object.send(name.to_s) || self.object.send(name.to_sym)
  end
end
