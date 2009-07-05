#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AddTagAction < Action
  attr_accessor :tag_name

  def run_against(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    models = args.flatten.compact
    models.flatten.compact.each do |model|
      model.tag(tag_name)
      model.save!
    end
  end

  def description
    "Add tag #{tag_name.inspect}"
  end
    
  def duplicate(account, options={})
    returning self.class.new do |action|
      action.tag_name = self.tag_name
    end
  end

  class << self
    def parameters
      [{:tag_name => {:type => :string}}]
    end
  end
end
