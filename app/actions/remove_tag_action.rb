#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RemoveTagAction < Action
  attr_accessor :tag_name

  def run_against(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    models = args.flatten.compact
    models.flatten.compact.each do |model|
      model.tag_list = model.tags.map(&:name).reject{|n| Tag.parse(tag_name).include?(n)}.join(",")
      model.save!
    end
  end

  def description
    "Remove tag #{tag_name.inspect}"
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
